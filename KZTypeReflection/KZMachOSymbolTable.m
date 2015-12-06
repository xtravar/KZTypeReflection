//
//  KZMachOSymbolTable.m
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 12/5/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

#import "KZMachOSymbolTable.h"

#import "KZMachOSymbolTable.h"
#import "KZMachOBindEntry.h"

@import MachO;
#import <dlfcn.h>
static int printClassPointers();

#define DATA_SECT_OBJC_CLASSREFS @"__objc_classrefs"
#define DATA_SECT_LA_SYMBOL_PTR @"__la_symbol_ptr"
#define DATA_SECT_NL_SYMBOL_PTR @"__nl_symbol_ptr"
#define DATA_SECT_JUMP_TABLE @"__jump_table"
// I don't actually know what 'got' is, but it seems to crop up sometimes
#define DATA_SECT_GOT @"__got"

static NSUInteger indexOfSection(NSString *name, struct section *sections, NSUInteger count) {
    const char *cname = name.UTF8String;
    for(NSUInteger i = 0; i < count; i++) {
        //NSLog(@"%@", @(sections[i].sectname));
        if(strcmp(cname, sections[i].sectname) == 0) {
            return i;
        }
    }
    return NSNotFound;
}

static NSUInteger indexOfSection64(NSString *name, struct section_64 *sections, NSUInteger count) {
    const char *cname = name.UTF8String;
    for(int i = 0; i < count; i++) {
        //NSLog(@"%@", @(sections[i].sectname));
        if(strcmp(cname, sections[i].sectname) == 0) {
            return i;
        }
    }
    return NSNotFound;
}

@implementation KZMachOSymbolTable {
    BOOL _is64;
    
    void *_baseOffset;
    void *_baseContentOffset;
    
    char const *_stringTable;
    const char *_stringTableMax;
    
#if defined(__LP64__)
    struct nlist_64 const *_symbolTable;
#else
    struct nlist const *_symbolTable;
#endif
    
    void * _objcClassRefs;
    
    uint32_t _lazySymbolTableOffset;
    NSUInteger _lazySymbolsIndex;
    
    uint32_t _nonLazySymbolTableOffset;
    NSUInteger _nonLazySymbolsIndex;
    
    uint32_t *_indirectSymbols;
    NSUInteger _indirectSymbolsCount;
    
    void *_jumpImportTableOffset;
    NSUInteger _jumpIndirectSymbolsIndex;
    
    
    NSDictionary *_localSymbolsByName;
    NSDictionary *_externalSymbolsByName;
    NSDictionary *_undefinedSymbolsByName;
    
    NSDictionary *_symbolsByNameToValue;
    
    NSMutableArray *_segments;
    NSMutableArray *_dylibs;
    NSMutableArray *_dyldInfos;
}

-(instancetype)init {
    void *addr = (dlsym(dlopen(NULL, RTLD_NOW), "main")); // (dlsym(dlopen(NULL, RTLD_NOW), "main"));
    
    return [self initWithAddress:addr];
}

-(instancetype)initWithAddress:(const void*)address {
    Dl_info dlinfo;
    if (dladdr(address, &dlinfo) == 0 || dlinfo.dli_fbase == NULL) {
        return nil;
    }
    return [self initWithDLInfo:dlinfo];
}

-(instancetype)initWithDLInfo:(Dl_info)dlinfo {
    self = [super init];
    if(self) {
        _segments = [NSMutableArray new];
        _dylibs = [NSMutableArray new];
        _dyldInfos = [NSMutableArray new];
        
        _baseOffset = dlinfo.dli_fbase;
        _modulePath = @(dlinfo.dli_fname);
        _moduleName = _moduleName.pathComponents.lastObject;
        
        struct mach_header * header = (struct mach_header*)_baseOffset;
        _is64 = (header->magic != MH_MAGIC);
        
        if(_is64) {
            [self _readImage64];
        } else {
            [self _readImage32];
        }
    }
    return self;
}


-(instancetype _Nonnull)initWithHeader:(const struct mach_header * _Nonnull)header {
    self = [super init];
    if(self) {
        _segments = [NSMutableArray new];
        _dylibs = [NSMutableArray new];
        _dyldInfos = [NSMutableArray new];
        
        _baseOffset = header;
        
        _is64 = (header->magic != MH_MAGIC);
        
        if(_is64) {
            [self _readImage64];
        } else {
            [self _readImage32];
        }
    }
    return self;
}

-(void)_readImage32 {
    struct mach_header * header = (struct mach_header*)_baseOffset;
    NSAssert(header->magic == MH_MAGIC, @"Unexpected magic value");
    
    _baseContentOffset = _baseOffset + sizeof(*header);
    
    [self _processCommands:header->ncmds];
}

-(void)_readImage64 {
    struct mach_header_64 * header =  (struct mach_header_64*)_baseOffset;
    NSAssert(header->magic == MH_MAGIC_64, @"Unexpected magic value");
    
    _baseContentOffset = _baseOffset + sizeof(*header);
    
    [self _processCommands:header->ncmds];
}

-(void)_processCommands:(uint32_t)numberOfCommands {
    struct load_command * cmd = (struct load_command *)_baseContentOffset;
    for(int i = 0; i < numberOfCommands; i++) {
        switch(cmd->cmd) {
            case LC_DYSYMTAB:
                [self _processLC_DYSYMTAB:(void*)cmd];
                break;
                
            case LC_SYMTAB:
                [self _processLC_SYMTAB:(void*)cmd];
                break;
                
            case LC_SEGMENT:
                [self _processLC_SEGMENT:(void*)cmd];
                break;
                
            case LC_SEGMENT_64:
                [self _processLC_SEGMENT64:(void*)cmd];
                break;
                
            case LC_DYLD_INFO:
            case LC_DYLD_INFO_ONLY:
                [_dyldInfos addObject:[NSValue valueWithPointer:cmd]];
                break;
                
            case LC_LOAD_DYLINKER:
                break;
                
            case LC_UUID:
                break;
                
            case LC_VERSION_MIN_IPHONEOS:
                break;
                
            case LC_SOURCE_VERSION:
                break;
                
            case LC_MAIN:
                break;
                
            case LC_LOAD_DYLIB:
                [self _processLC_LOAD_DYLIB:cmd];
                break;
                
            case LC_RPATH:
                break;
                
            case LC_DYLD_ENVIRONMENT:
                break;
                
            case LC_DATA_IN_CODE:
                break;
                
            case LC_FUNCTION_STARTS:
                break;
                
            case LC_DYLIB_CODE_SIGN_DRS:
                break;
                
            default:
                break;
        }
        cmd = (struct load_command *)((uint8_t *)cmd + cmd->cmdsize);
    }
    
    for(NSValue *dyldInfo in _dyldInfos) {
        [self _processLC_DYLD_INFO:dyldInfo.pointerValue];
    }
}

-(void)_processLC_DYLD_INFO:(struct dyld_info_command*)cmd {
    NSData *data = [NSData dataWithBytesNoCopy:_baseOffset + cmd->bind_off
                                        length:cmd->bind_size
                                  freeWhenDone:NO];
    NSInputStream *stream = [NSInputStream inputStreamWithData:data];
    [stream open];
    
    NSArray *array = [KZMachOBindEntry entriesFromStream:stream pointerSize:sizeof(void*)];
    for (KZMachOBindEntry *entry in array) {
        uint64_t offset = entry.offset;
        if(sizeof(void*) == 8) {
            struct segment_command_64 *seg = [_segments[entry.segmentIndex] pointerValue];
            offset += seg->fileoff;
        } else {
            struct segment_command *seg = [_segments[entry.segmentIndex] pointerValue];
            offset += seg->fileoff;
        }
        //void *ptr = _baseOffset + offset;
    }
    [stream close];
    
    return;
}

-(void)_processLC_LOAD_DYLIB:(struct dylib_command*)cmd {
    [_dylibs addObject:[NSValue valueWithPointer:cmd]];
    
    // why is there +1?
    const char *cname = _stringTable + cmd->dylib.name.offset + 1;
    NSString *name = @(cname);
    NSLog(@"load %@", name.pathComponents.lastObject);
}

-(NSDictionary*)_process_LC_DYSYMTAB_symbolsByNameWithIndex:(NSInteger)index count:(NSInteger)count {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
#if defined(__LP64__)
    struct nlist_64 const * entries;
#else
    struct nlist const * entries;
#endif
    
    entries = _symbolTable + index;
    for (int i = 0; i < count; i++) {
        typeof(entries) entry = &entries[i];
        
        char const *cname;
#if defined(__LP64__)
        cname = _stringTable + entry->n_un.n_strx;
#else
        cname = _stringTable + entry->n_un.n_strx;
        //cname = entry->n_un.n_name;
#endif
        if(cname >= _stringTableMax) {
            continue;
        }
        NSString *name = @(cname);
        if(!name.length) {
            continue;
        }
        
        dict[name] = @(index + i);
    }
    return [dict copy];
}


-(void)_processLC_DYSYMTAB:(struct dysymtab_command *)cmd {
    _indirectSymbols = _baseOffset + cmd->indirectsymoff;
    _indirectSymbolsCount = cmd->nindirectsyms;
    
    _localSymbolsByName = [self _process_LC_DYSYMTAB_symbolsByNameWithIndex:cmd->ilocalsym count:cmd->nlocalsym];
    _externalSymbolsByName = [self _process_LC_DYSYMTAB_symbolsByNameWithIndex:cmd->iextdefsym count:cmd->nextdefsym];
    _undefinedSymbolsByName = [self _process_LC_DYSYMTAB_symbolsByNameWithIndex:cmd->iundefsym count:cmd->nundefsym];
    
    return;
}

-(void)_processLC_SYMTAB:(struct symtab_command *)cmd {
    NSMutableDictionary *dict = [NSMutableDictionary new];
    
    _stringTable = _baseOffset + cmd->stroff;
    _stringTableMax = _stringTable + cmd->strsize;
    _symbolTable = _baseOffset + cmd->symoff;
    
#if defined(__LP64__)
    struct nlist_64 const * entries;
#else
    struct nlist const * entries;
#endif
    entries = _symbolTable;
    for(int i = 0; i < cmd->nsyms; i++) {
        typeof(entries) entry = &entries[i];
        char const *cname;
#if defined(__LP64__)
        cname = _stringTable + entry->n_un.n_strx;
#else
        cname = _stringTable + entry->n_un.n_strx;
        //cname = entry->n_un.n_name;
#endif
        //TODO: remind myself why these checks were here before
        //uint8_t type = (entry->n_type & N_TYPE);
        //BOOL ext = (entry->n_type & N_EXT) != 0;
        
        if(cname >= _stringTableMax) {
            continue;
        }
        
        NSString *name = @(cname);
        //if(type == N_UNDF && ext) {
            dict[name] = @(i);
        //}
        continue;
    }
    _symbolsByNameToValue = [dict copy];
}

-(void)_processLC_SEGMENT:(struct segment_command *)cmd {
    [_segments addObject:[NSValue valueWithPointer:cmd]];
    
    uint32_t nsects = cmd->nsects;
    struct section *sections = (void*)(uint8_t*)cmd + sizeof(struct segment_command);
    
    if(strcmp(cmd->segname, SEG_DATA) == 0) {
        NSUInteger index = indexOfSection(DATA_SECT_LA_SYMBOL_PTR, sections, nsects);
        if(index != NSNotFound) {
            _lazySymbolTableOffset = sections[index].offset;
            _lazySymbolsIndex = sections[index].reserved1;
        }
        
        index = indexOfSection(@"__objc_classrefs", sections, nsects);
        if(index != NSNotFound) {
            _objcClassRefs = _baseOffset + sections[index].offset;
        }
        
        index = indexOfSection(DATA_SECT_NL_SYMBOL_PTR, sections, nsects);
        if(index != NSNotFound) {
            _nonLazySymbolTableOffset = sections[index].offset;
            _nonLazySymbolsIndex = sections[index].reserved1;
        }
        return;
    }
    
    
    if(strcmp(cmd->segname, SEG_IMPORT) == 0) {
        NSUInteger index = indexOfSection(DATA_SECT_JUMP_TABLE, sections, nsects);
        if(index != NSNotFound) {
            _jumpImportTableOffset = (void*)(uint64_t)sections[index].addr;
            _jumpIndirectSymbolsIndex = sections[index].reserved1;
        }
        return;
    }
    
    if(strcmp(cmd->segname, SEG_LINKEDIT) == 0) {
        NSLog(@"LinkEdit - %p", (void*)cmd->fileoff);
    }
}

-(void)_processLC_SEGMENT64:(struct segment_command_64 *)cmd {
    [_segments addObject:[NSValue valueWithPointer:cmd]];
    
    uint32_t nsects = cmd->nsects;
    struct section_64 *sections = (void*)(uint8_t*)cmd + sizeof(struct segment_command_64);
    //NSLog(@"%@", @(cmd->segname));
    if(strcmp(cmd->segname, SEG_DATA) == 0) {
        NSUInteger index = indexOfSection64(DATA_SECT_LA_SYMBOL_PTR, sections, nsects);
        if(index != NSNotFound) {
            _lazySymbolTableOffset = sections[index].offset;
            _lazySymbolsIndex = sections[index].reserved1;
        }
        
        index = indexOfSection64(@"__objc_classrefs", sections, nsects);
        if(index != NSNotFound) {
            _objcClassRefs = (void*)(_baseOffset + sections[index].offset);
        }
        return;
    }
    
    if(strcmp(cmd->segname, SEG_IMPORT) == 0) {
        NSUInteger index = indexOfSection64(DATA_SECT_JUMP_TABLE, sections, nsects);
        if(index != NSNotFound) {
            _jumpImportTableOffset = (void*)sections[index].addr;
            _jumpIndirectSymbolsIndex = sections[index].reserved1;
        }
        return;
    }
    
    
    if(strcmp(cmd->segname, SEG_LINKEDIT) == 0) {
        NSLog(@"LinkEdit - %p", (void*)cmd->fileoff);
        return;
    }
}

-(void)verifySymbols {
    for(NSString *name in _symbolsByNameToValue) {
        if(!_localSymbolsByName[name] && !_externalSymbolsByName[name] && !_undefinedSymbolsByName[name]) {
            //NSLog(@"ndgsdg");
        }
    }
    
    for(NSString *name in _localSymbolsByName) {
        if(!_symbolsByNameToValue[name]) {
            NSLog(@"undefined local: %@", name);
        }
    }
    for(NSString *name in _externalSymbolsByName) {
        if(!_symbolsByNameToValue[name]) {
            NSLog(@"undefined external: %@", name);
        }
    }
    for(NSString *name in _undefinedSymbolsByName) {
        if(!_symbolsByNameToValue[name]) {
            NSLog(@"undefined undefined: %@", name);
        }
    }
    
}

-(void)logSymbolsByName {
    NSLog(@"------local------");
    for(NSString *name in _localSymbolsByName) {
        void *ptr = [self pointerForSymbol:name];
        
        if(!ptr) {
            NSLog(@"%@ - NONE - %@", name, _symbolsByNameToValue[name]);
        } else {
            NSLog(@"%@ - %p", name, ptr);
        }
    }
    
    NSLog(@"------exter------");
    for(NSString *name in _externalSymbolsByName) {
        void *ptr = [self pointerForSymbol:name];
        
        if(!ptr) {
            NSLog(@"%@ - NONE - %@", name, _symbolsByNameToValue[name]);
        } else {
            NSLog(@"%@ - %p", name, ptr);
        }
    }
    
    NSLog(@"------undef------");
    for(NSString *name in _undefinedSymbolsByName) {
        void *ptr = [self pointerForSymbol:name];
        
        if(!ptr) {
            NSLog(@"%@ - NONE - %@", name, _symbolsByNameToValue[name]);
        } else {
            NSLog(@"%@ - %p", name, ptr);
        }
    }
    printClassPointers();
}

-(void*)pointerForSymbol:(NSString*)symbol {
    NSNumber *indexNum = _symbolsByNameToValue[symbol];
    
    if(!indexNum) {
        return NULL;
    }
    
    NSUInteger index = indexNum.unsignedIntegerValue;
    for(NSUInteger i = _lazySymbolsIndex; i < _indirectSymbolsCount; i++) {
        uint32_t indirectSymbolNum = _indirectSymbols[i];
        
        if(indirectSymbolNum == index) {
            NSUInteger import_table_entry_index = i - _lazySymbolsIndex;
            
            void *retval = (size_t *)((char const *)(_baseOffset) + _lazySymbolTableOffset
                                      + import_table_entry_index * sizeof(size_t));
            
            return retval;
        }
    }
    
    for(NSUInteger i = _lazySymbolsIndex; i < _indirectSymbolsCount; i++) {
        uint32_t indirectSymbolNum = _indirectSymbols[i];
        
        if(indirectSymbolNum == index) {
            NSUInteger import_table_entry_index = i - _lazySymbolsIndex;
            
            void *retval = (size_t *)((char const *)(_baseOffset) + _lazySymbolTableOffset
                                      + import_table_entry_index * sizeof(size_t));
            
            return retval;
        }
    }
    
    
    return NULL;
    
}


@end


@import MachO;

#include <dlfcn.h>

void processCommands64(struct mach_header_64 *header) {
    char const *string_table = 0;  //buffer to read string_table table from file
    struct nlist_64 const *symbol_table = 0;  //buffer to read symbol table from file
    
    struct load_command * cmd = (struct load_command *)(header + 1);
    //uint8_t *cmdPtr = (uint8_t*)header + sizeof(header);
    
    for (uint32_t i = 0; i < header->ncmds; i++) {
        //struct load_command *cmd = (struct load_command*)cmdPtr;
        
        if(cmd->cmd == LC_SEGMENT_64) {
            struct segment_command_64 *seg = (struct segment_command_64*)cmd;
        } else if(cmd->cmd == LC_DYSYMTAB) {
            struct dysymtab_command *dsc = (struct dysymtab_command*)cmd;
            
            uint32_t symbol_table_entry_index = dsc->iundefsym;
            struct nlist_64 const * symbol_table_entry = symbol_table + symbol_table_entry_index; //now we're at the first undefined symbol in the symbol table
            
            for (int i = 0; i < dsc->nundefsym; ++i)  //find the target symbol by specified function's name
            {
                char const *symbol_name = string_table + symbol_table_entry->n_un.n_strx;  //shift to name in the string table
                
                if(strcmp(symbol_name, "_OBJC_CLASS_$_UIAlertController") == 0) {
                    //NSLog(@"");
                }
                /*
                 if ('_' == *symbol_name)  //each name in Mach-O starts with underscore
                 if (!strcmp(function_name, symbol_name + 1))  //shift by one to avoid leading underscore
                 {
                 symbol_table_entry_index += i;  //index correction, now we've got an index of the target symbol in symbol table
                 symbol_found = 1;
                 
                 break;
                 }
                 
                 */
                ++symbol_table_entry;
                //NSLog(@"%@", @(symbol_name));
            }
            
            
            
            //nlist_64
        } else if(cmd->cmd == LC_SYMTAB) {
            struct symtab_command *sc = (struct symtab_command*)cmd;
            string_table = (uint8_t*)header + sc->stroff;
            symbol_table = (uint8_t*)header + sc->symoff;
            //NSLog(@"");
        }
        cmd = (struct load_command *)((uint8_t *)cmd + cmd->cmdsize);
    }
}
void findPtr(void *start, void *needle) {
    for(void *i = start; ; i++) {
        if(needle == *(void**)(i)) {
            NSLog(@"FOUND");
            return;
        }
    }
    return;
}

static int printClassPointers() {
    Dl_info dlinfo;
    
    if (dladdr(printClassPointers, &dlinfo) == 0 || dlinfo.dli_fbase == NULL) {
        return 0; // Can't find symbol for main
    }
    uint32_t magic = *((uint32_t*)dlinfo.dli_fbase);
    
    unsigned long size;
    void **classes;
    
    if(magic == MH_MAGIC_64) {
        const struct mach_header_64 * header = dlinfo.dli_fbase;
        classes = (void**)getsectiondata(header, SEG_DATA, "__objc_classrefs", &size);
        //size = sect->size;
    } else if(magic == MH_MAGIC) {
        const struct mach_header * header = dlinfo.dli_fbase;
        classes = (void**)getsectiondata(header, SEG_DATA, "__objc_classrefs", &size);
    } else {
        return 0;
    }
    
    
    long count = size / sizeof(Class);
    for(int i = 0; i < count; i++) {
        Class cls = (__bridge Class)classes[i];
        NSLog(@"%@ - %@ - %p", @(i), [cls description], &classes[i]);
        if(!cls) {
            // this is our problem
        }
    }
    return 0;
}


int printClassNames() {
    Dl_info dlinfo;
    //
    
    if (dladdr(printClassNames, &dlinfo) == 0 || dlinfo.dli_fbase == NULL) {
        return 0; // Can't find symbol for main
    }
    
    
    uint32_t magic = *((uint32_t*)dlinfo.dli_fbase);
    
    unsigned long size;
    void **classes;
    
    void **classes2;
    
    struct relocation_info *relInfos;
    
    uint64_t diff = 0;
    
    if(magic == MH_MAGIC_64) {
        const struct mach_header_64 * header = dlinfo.dli_fbase;
        processCommands64(header);
        classes = (void**)getsectiondata(header, SEG_DATA, "__objc_classlist", &size);
        struct section_64 *sect = getsectbynamefromheader_64(header, SEG_DATA, "__objc_classlist");
        uint64_t diff = classes - sect->addr;
        relInfos = sect->addr;
        classes2 = (uint8_t*)dlinfo.dli_fbase + sect->offset;
        diff = classes - classes2;
        //size = sect->size;
    } else if(magic == MH_MAGIC) {
        const struct mach_header * header = dlinfo.dli_fbase;
        classes = (void**)getsectiondata(header, SEG_DATA, "__objc_classlist", &size);
        struct section *sect = getsectbynamefromheader(header, SEG_DATA, "__objc_classlist");
        
    } else {
        return 0;
    }
    
    
    long count = size / sizeof(Class);
    for(int i = 0; i < count; i++) {
        Class cls = (__bridge Class)classes[i];
        NSLog(@"%@ - %@ - %p", @(i), [cls description], &classes[i]);
        if(!cls) {
            //findPtr(dlinfo.dli_fbase, &classes[i]);
        }
    }
    return 0;
}
