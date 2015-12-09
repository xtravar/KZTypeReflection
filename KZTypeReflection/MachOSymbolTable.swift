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
    public var segments = [MachOSegment]()
    
    var dynamicSymbols = [String: DynamicReference]()
    var symbolsToAddresses = [String: UnsafePointer<Void>]()
    var indirectSymbolsToAddresses = [String: UnsafePointer<Void>]()
    
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
    public var onlySwiftMetadataSymbols = false
    
    public let offset: Int
    
    /*
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
    */
    public init(baseAddress: UnsafePointer<Void>, offset: Int) {
        self.moduleName = ""
        self.baseOffset = baseAddress
        self.offset = offset
        
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
        // save these for after - need the segments completely loaded
        var dyldInfos = [dyld_info_command]()
        
        var cmdPtr = UnsafePointer<Int8>(offset)
        
        for _ in 0 ..< numberOfCommands {
            let cmd = UnsafePointer<load_command>(cmdPtr).memory
            let type = LoadCommandType(value: cmd.cmd & ~LC_REQ_DYLD)
            
            
            switch(type) {
            case .UNKNOWN(let identifier):
                break
                
            case .SEGMENT:
                let seg = UnsafePointer<segment_command>(cmdPtr)
                segments.append(MachOSegment(command: seg, baseAddress: self.baseOffset))
                break
                
            case .SYMTAB:
                if is64 {
                    self.process_LC_SYMTAB(nlist_64_real.self, cmd: UnsafePointer<symtab_command>(cmdPtr))
                } else {
                    self.process_LC_SYMTAB(nlist_real.self, cmd: UnsafePointer<symtab_command>(cmdPtr))
                }
                break
                
            case .SYMSEG:
                break
            case .THREAD:
                break
            case .UNIXTHREAD:
                break
            case .LOADFVMLIB:
                break
            case .IDFVMLIB:
                break
            case .IDENT:
                break
            case .FVMFILE:
                break
            case .PREPAGE:
                break
            case .DYSYMTAB:
                self.process_LC_DYSYMTAB(UnsafePointer<dysymtab_command>(cmdPtr))
                break
                
            case .LOAD_DYLIB:
                _process_LC_LOAD_DYLIB(UnsafePointer<dylib_command>(cmdPtr))
                break
            case .ID_DYLIB:
                break
            case .LOAD_DYLINKER:
                break
            case .ID_DYLINKER:
                break
            case .PREBOUND_DYLIB:
                break
            case .ROUTINES:
                break
            case .SUB_FRAMEWORK:
                break
            case .SUB_UMBRELLA:
                break
            case .SUB_CLIENT:
                break
            case .SUB_LIBRARY:
                break
            case .TWOLEVEL_HINTS:
                break
            case .PREBIND_CKSUM:
                break
            case .SEGMENT_64:
                let seg = UnsafePointer<segment_command_64>(cmdPtr)
                segments.append(MachOSegment(command: seg, baseAddress: self.baseOffset))
                break
                
            case .ROUTINES_64:
                break
            case .UUID:
                break
            case .CODE_SIGNATURE:
                break
            case .SEGMENT_SPLIT_INFO:
                break
            case .LAZY_LOAD_DYLIB:
                break
            case .ENCRYPTION_INFO:
                break
            case .DYLD_INFO:
                dyldInfos.append(UnsafePointer<dyld_info_command>(cmdPtr).memory)
                break
            case .VERSION_MIN_MACOSX:
                break
            case .VERSION_MIN_IPHONEOS:
                break
            case .FUNCTION_STARTS:
                break
            case .DYLD_ENVIRONMENT:
                break
            case .DATA_IN_CODE:
                break
            case .SOURCE_VERSION:
                break
            case .DYLIB_CODE_SIGN_DRS:
                break
            case .ENCRYPTION_INFO_64:
                break
            case .LINKER_OPTION:
                break
            case .LINKER_OPTIMIZATION_HINT:
                break
            case .VERSION_MIN_TVOS:
                break
            case .VERSION_MIN_WATCHOS:
                break
            }
            cmdPtr += Int(cmd.cmdsize)
        }
        
        for dyldInfo in dyldInfos {
            //self.processDyldInfoCommand(dyldInfo, segments: segments)
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
            
            let symType = entry.symbolType
            
    
            if case SymbolType.UNDF = symType {
                continue
            }
            
            guard let name = getString(entry.n_strx) else {
                continue
            }
            
            guard name != "" else {
                continue
            }
            
            let ptr = UnsafePointer<Void>(bitPattern: entry.n_value)
            if ptr == nil {
                continue
            }
            
            //print("\(entry.symbolType) - \(entry.isReferenceToWeak) - \(entry.isExternal) - \(entry.isPrivateExternal) - \(entry.isReferencedDynamically) - \(name)")
            
            if name == "__MdSi" {
                print("OK")
            }
            if entry.isReferenceToWeak {
                if let _ = symbolsToAddresses[name] {
                    //print("ok")
                } else if let _ = indirectSymbolsToAddresses[name] {
                    //print("OK")
                } else {
                    self.indirectSymbolsToAddresses[name] = ptr
                }
            } else {
                if let _ = symbolsToAddresses[name] {
                    //print("OK")
                    
                } else {
                    self.symbolsToAddresses[name] = ptr
                }
            }
        }
        
    }
    
    private func getString(offset: UInt32) -> String? {
        let ptr = self.stringTable + Int(offset)
        if ptr >= self.stringTableEnd {
            return nil
        }
        
        if onlySwiftSymbols {
            if onlySwiftMetadataSymbols {
                if strncmp(ptr, "__TMd", 5) != 0 && strncmp(ptr, "__TMa", 5) != 0 {
                    return nil
                }
            } else if strncmp(ptr, "__T", 3) != 0 {
                return nil
            }
        }
        let retval = String.fromCString(ptr)!
        return retval
    }
    
    public func addressOfSymbol(name: String) -> UnsafePointer<Void>? {
        return self.symbolsToAddresses[name]
    }
    
    public func forEachSymbol(each: (String, UnsafePointer<Void>) -> Void) {
        self.symbolsToAddresses.forEach { each($0, $1.advancedBy(self.offset)) }
    }
    
    public func forEachIndirectSymbol(each: (String, UnsafePointer<Void>) -> Void) {
        self.indirectSymbolsToAddresses.forEach {
            let ptr = UnsafePointer<UnsafePointer<Void>>($1.advancedBy(self.offset))
            let retval = ptr[1]
            if retval == nil {
                return
            }
            each($0, retval)

        }
    }
    
}