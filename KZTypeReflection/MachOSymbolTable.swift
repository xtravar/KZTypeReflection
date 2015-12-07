//
//  MachOSymbolTable.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 12/4/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import MachO

private let DATA_SECT_OBJC_CLASSREFS = "__objc_classrefs"
private let DATA_SECT_LA_SYMBOL_PTR = "__la_symbol_ptr"
private let DATA_SECT_NL_SYMBOL_PTR = "__nl_symbol_ptr"
// I don't actually know what 'got' is, but it seems to crop up sometimes
private let DATA_SECT_GOT = "__got"

private extension UnsafePointer {
    func advancedBy<T: UnsignedIntegerType>(n: T) -> UnsafePointer<Memory> {
        return self.advancedBy(Int(n.toIntMax()))
    }
    
    init<T: UnsignedIntegerType>(bitPattern: T) {
        self.init(bitPattern: UInt(bitPattern.toUIntMax()))
    }
}

public class MachOSymbolTable {
    typealias DynamicReference = UnsafeMutablePointer<UnsafeMutablePointer<Void>>
    
    public let moduleName: String
    public let baseOffset: UnsafePointer<Void>
    
    var dynamicSymbols = [String: DynamicReference]()
    var symbolsToAddresses = [String: UnsafePointer<Void>]()
    
    let is64: Bool
    
    var stringTable: UnsafePointer<Int8> = nil
    var stringTableEnd: UnsafePointer<Int8> = nil
    
    var symbolTable: UnsafePointer<Void> = nil
    
    var symbolsByNameToReference = [String: UnsafePointer<Void>]()
    
    
    var indirectSymbols: UnsafePointer<UInt32> = nil
    var indirectSymbolsCount: UInt = 0
    
    var localSymbolsByName = [String: Int]()
    var externalSymbolsByName = [String: Int]()
    var undefinedSymbolsByName = [String: Int]()
    
    public var onlySwiftSymbols = false
    
    convenience public init?() {
        self.init(address:unsafeBitCast(MachOSymbolTable.self, UnsafePointer<Void>.self))
    }
    
    convenience public init?(symbolAddress: UnsafePointer<Void>) {
        var dlinfo = dl_info()
        if dladdr(symbolAddress, &dlinfo) == 0 || dlinfo.dli_fbase == nil {
            return nil
        }
        
        self.init(dlinfo: dlinfo)
    }
    
    convenience public init?(address: UnsafePointer<Void>) {
        var dlinfo = dl_info()
        if dladdr(address, &dlinfo) == 0 || dlinfo.dli_fbase == nil {
            return nil
        }
        
        self.init(dlinfo: dlinfo)
    }
    
    convenience public init(dlinfo: dl_info) {
        self.init(baseAddress: dlinfo.dli_fbase)
    }
    
    public init(baseAddress: UnsafePointer<Void>) {
        self.moduleName = ""
        self.baseOffset = baseAddress
        
        let magic = UnsafePointer<UInt32>(self.baseOffset).memory
        if magic == mach_header.magicValue {
            self.is64 = false
        } else {
            self.is64 = true
        }
    }
    
    public func load() {
        if self.is64 {
            self.readImage(mach_header_64.self)
        } else {
            self.readImage(mach_header.self)
        }
    }
    
    func readImage<T: MachOHeaderType>(headerType: T.Type) {
        let hdr = UnsafePointer<T>(self.baseOffset).memory
        precondition(hdr.magic == T.magicValue, "Unexpected magic value")
        
        self.processCommands(hdr.ncmds, offset: self.baseOffset.advancedBy(sizeof(T.self)))
    }
    
    func processCommands(numberOfCommands: UInt32, offset: UnsafePointer<Void>) {
        var segments = [MachOSegment]()
        // save these for after - need the segments completely loaded
        var dyldInfos = [dyld_info_command]()
        
        var cmdPtr = UnsafePointer<Int8>(offset)
        
        for _ in 0 ..< numberOfCommands {
            let cmd = UnsafePointer<load_command>(cmdPtr).memory
            
            switch(unsafeBitCast(cmd.cmd, Int32.self)) {
            // LC_DYSYMTAB
            case dysymtab_command.commandValue:
                self.process_LC_DYSYMTAB(UnsafePointer<dysymtab_command>(cmdPtr))
                break;
                
            // LC_SYMTAB
            case symtab_command.commandValue:
                if is64 {
                    self.process_LC_SYMTAB(nlist_64_real.self, cmd: UnsafePointer<symtab_command>(cmdPtr))
                } else {
                    self.process_LC_SYMTAB(nlist_real.self, cmd: UnsafePointer<symtab_command>(cmdPtr))
                }
                
                break;
                
            // LC_SEGMENT
            case segment_command.commandValue:
                let seg = UnsafePointer<segment_command>(cmdPtr)
                segments.append(MachOSegment(command: seg, baseAddress: self.baseOffset))
                break
                
            // LC_SEGMENT_64
            case segment_command_64.commandValue:
                let seg = UnsafePointer<segment_command_64>(cmdPtr)
                segments.append(MachOSegment(command: seg, baseAddress: self.baseOffset))
                break
                
            // LC_DYLD_INFO
            case dyld_info_command.commandValue:
                dyldInfos.append(UnsafePointer<dyld_info_command>(cmdPtr).memory)
                break
                
            case LC_LOAD_DYLINKER:
                break;
                
            case LC_UUID:
                break;
                
            case LC_VERSION_MIN_IPHONEOS:
                break;
                
            case LC_SOURCE_VERSION:
                break;
            
            // LC_DYLD_INFO
            case dylib_command.commandValue:
                _process_LC_LOAD_DYLIB(UnsafePointer<dylib_command>(cmdPtr))
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
                break
                
            }
            cmdPtr += Int(cmd.cmdsize)
        }
        
        for dyldInfo in dyldInfos {
            self.processDyldInfoCommand(dyldInfo, segments: segments)
        }
        
    }
    
    
    func processDyldInfoCommand(cmd: dyld_info_command, segments: [MachOSegment]) {
        // making this a stream just makes life that much easier
        let data = NSData(bytesNoCopy: UnsafeMutablePointer<Void>(self.baseOffset.advancedBy(Int(cmd.bind_off))), length: Int(cmd.bind_size), freeWhenDone: false)
        let stream = NSInputStream(data: data)
        stream.open()
        defer { stream.close() }
        
        let array = MachOBindEntry.entriesFromStream(stream, pointerSize: sizeof(Int.self))
        for entry in array {
            let segment = segments[entry.segmentIndex]
            guard segment.name == SEG_DATA else {
                continue
            }
            
            let ptr = segment.address + Int(entry.offset)
            let section = segment.sectionContainingAddress(ptr)!
            
            switch(section.name) {
            case DATA_SECT_OBJC_CLASSREFS:
                break
            case DATA_SECT_NL_SYMBOL_PTR:
                break
            case DATA_SECT_GOT:
                break
            default:
                //print("\(entry.symbolName) - \(section.name)")
                continue
            }

            self.symbolsToAddresses[entry.symbolName] = ptr
        }
    }
    
    private func _process_LC_LOAD_DYLIB(cmd: UnsafePointer<dylib_command>) {
    
    }
    
    private func process_LC_DYSYMTAB(cmd: UnsafePointer<dysymtab_command>) {
        let c = cmd.memory
        self.indirectSymbols = UnsafePointer<UInt32>(self.baseOffset).advancedBy(Int(c.indirectsymoff))
        self.indirectSymbolsCount = UInt(c.nindirectsyms)
        
        if is64 {
            let list = nlist_64_real.self
            self.localSymbolsByName = self.process_LC_DYSYMTAB_symbolsByNameWithIndex(list, index: Int(c.ilocalsym), count: Int(c.nlocalsym))
            self.externalSymbolsByName = self.process_LC_DYSYMTAB_symbolsByNameWithIndex(list, index: Int(c.iextdefsym), count: Int(c.nextdefsym))
            self.undefinedSymbolsByName = self.process_LC_DYSYMTAB_symbolsByNameWithIndex(list, index: Int(c.iundefsym), count: Int(c.nundefsym))
        } else {
            let list = nlist_real.self
            self.localSymbolsByName = self.process_LC_DYSYMTAB_symbolsByNameWithIndex(list, index: Int(c.ilocalsym), count: Int(c.nlocalsym))
            self.externalSymbolsByName = self.process_LC_DYSYMTAB_symbolsByNameWithIndex(list, index: Int(c.iextdefsym), count: Int(c.nextdefsym))
            self.undefinedSymbolsByName = self.process_LC_DYSYMTAB_symbolsByNameWithIndex(list, index: Int(c.iundefsym), count: Int(c.nundefsym))
        }

    }
    
    
    private func process_LC_DYSYMTAB_symbolsByNameWithIndex<T: MachONlistType>(listType: T.Type, index: Int, count: Int) -> [String: Int] {
        var dict = [String: Int]()
        
        let entries = UnsafePointer<T>(self.symbolTable).advancedBy(index)
        for i in 0 ..< count {
            guard let name = getString(entries[i].n_strx) else {
                continue
            }
            
            guard name != "" else {
                continue
            }
            
            dict[name] = index + 1
            
        }
        
        return dict
    }
    
    private func process_LC_SYMTAB<T: MachONlistType>(listType: T.Type, cmd: UnsafePointer<symtab_command>) {
        let c = cmd.memory
        
        self.stringTable = UnsafePointer<Int8>(self.baseOffset).advancedBy(c.stroff)
        self.stringTableEnd = self.stringTable.advancedBy(c.strsize)
        
        self.symbolTable = self.baseOffset.advancedBy(c.symoff)
        
        let entries = UnsafePointer<T>(self.symbolTable)
        for i in 0 ..< Int(c.nsyms) {
            let entry = entries[i]
    
//            let type = (Int32(entry.n_type) & N_TYPE)
//            let ext = (Int32(entry.n_type) & N_EXT) != 0
//            
//            if type == N_UNDF || ext {
//                continue
//            }
            
            guard let name = getString(entry.n_strx) else {
                continue
            }
            
            guard name != "" else {
                continue
            }
            
            let ptr = UnsafePointer<Void>(bitPattern: entry.n_value)
            
            self.symbolsToAddresses[name] = ptr
        }
        
    }
    
    private func getString(offset: UInt32) -> String? {
        let ptr = self.stringTable + Int(offset)
        if ptr >= self.stringTableEnd {
            return nil
        }
        
        if onlySwiftSymbols {
            if strncmp(ptr, "__T", 3) != 0 {
                return nil
            }
        }
        return String.fromCString(ptr)
    }
    
    public func addressOfSymbol(name: String) -> UnsafePointer<Void>? {
        return self.symbolsToAddresses[name]
    }
    
    public func forEachSymbol(each: (String, UnsafePointer<Void>) -> Void) {
        self.symbolsToAddresses.forEach { each($0, $1) }
    }
    
}