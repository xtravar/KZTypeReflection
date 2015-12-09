//
//  MachHelpers.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 12/4/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import MachO
import Darwin

//MARK: header
public protocol MachOHeaderType {
    static var magicValue: UInt32 {get}
    
    var magic: UInt32 {get} /* mach magic number identifier */
    var cputype: cpu_type_t{get} /* cpu specifier */
    var cpusubtype: cpu_subtype_t{get} /* machine specifier */
    var filetype: UInt32{get} /* type of file */
    var ncmds: UInt32{get} /* number of load commands */
    var sizeofcmds: UInt32{get} /* the size of all the load commands */
    var flags: UInt32{get} /* flags */
    
}

extension mach_header : MachOHeaderType {
    public static var magicValue: UInt32 = MH_MAGIC
}


extension mach_header_64 : MachOHeaderType {
    public static var magicValue: UInt32 = MH_MAGIC_64
}


//MARK: load command
public protocol MachOLoadCommandType {
}

//MARK: segment command
public protocol MachOSegmentType : MachOLoadCommandType {
    typealias AddressType: UnsignedIntegerType
    typealias SectionType: MachOSectionType
    
    var cmd: UInt32 { get }
    var cmdsize: UInt32 { get }
    
    var segname: (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8) { get }
    
    var vmaddr: AddressType	 { get }	/* memory address of this segment */
    var	vmsize: AddressType	{ get }	/* memory size of this segment */
    var	fileoff: AddressType { get }	/* file offset of this segment */
    var	filesize: AddressType { get }	/* amount to map from the file */
    
    var	maxprot: vm_prot_t { get }	/* maximum VM protection */
    var	initprot: vm_prot_t { get }	/* initial VM protection */
    var	nsects: UInt32 { get }		/* number of sections in segment */
    var	flags: UInt32 { get }		/* flags */
}

extension segment_command : MachOSegmentType {
    public typealias AddressType = UInt32
    public typealias SectionType = section
    
    public static let commandValue = LC_SEGMENT
}

extension segment_command_64 : MachOSegmentType {
    public typealias AddressType = UInt64
    public typealias SectionType = section_64
    
    public static let commandValue = LC_SEGMENT_64
}


//MARK: section
public protocol MachOSectionType {
    typealias AddressType: UnsignedIntegerType
    
    var sectname: (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8) { get } /* for 32-bit architectures */ /* name of this section */
    var segname: (Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8, Int8) { get } /* segment this section goes in */
    var addr: AddressType { get } /* memory address of this section */
    var size: AddressType { get } /* size in bytes of this section */
    var offset: UInt32 { get } /* file offset of this section */
    var align: UInt32 { get } /* section alignment (power of 2) */
    var reloff: UInt32 { get } /* file offset of relocation entries */
    var nreloc: UInt32 { get } /* number of relocation entries */
    var flags: UInt32 { get } /* flags (section type and attributes)*/
    var reserved1: UInt32 { get } /* reserved (for offset or index) */
    var reserved2: UInt32 { get } /* reserved (for count or sizeof) */
}

extension section: MachOSectionType {
    public typealias AddressType = UInt32
}

extension section_64: MachOSectionType {
    public typealias AddressType = UInt64
}


//MARK dylib_module
public protocol MachOModuleType {
    typealias AddressType: UnsignedIntegerType
    
    var module_name: UInt32 { get } /* the module name (index into string table) */
    
    var iextdefsym: UInt32 { get } /* index into externally defined symbols */
    var nextdefsym: UInt32 { get } /* number of externally defined symbols */
    var irefsym: UInt32 { get } /* index into reference symbol table */
    var nrefsym: UInt32 { get } /* number of reference symbol table entries */
    var ilocalsym: UInt32 { get } /* index into symbols for local symbols */
    var nlocalsym: UInt32 { get } /* number of local symbols */
    
    var iextrel: UInt32 { get } /* index into external relocation entries */
    var nextrel: UInt32 { get } /* number of external relocation entries */
    
    var iinit_iterm: UInt32 { get } /* low 16 bits are the index into the init
    section, high 16 bits are the index into
    the term section */
    
    var ninit_nterm: UInt32 { get } /* low 16 bits are the number of init section
    entries, high 16 bits are the number of
    term section entries */
    
    var objc_module_info_addr: AddressType { get } /* for this module address of the start of */
    /*  the (__OBJC,__module_info) section */
    var objc_module_info_size: UInt32 { get } /* for this module size of */
}

extension dylib_module : MachOModuleType {
    public typealias AddressType = UInt32
}

extension dylib_module_64 : MachOModuleType {
    public typealias AddressType = UInt64
}


//MARK: other commands


//MARK: nlist

protocol MachONlistType {
    typealias AddressType: UnsignedIntegerType
    
    var n_strx: UInt32 { get }
    var n_type: UInt8 { get } /* type flag, see below */
    var n_sect: UInt8 { get } /* section number or NO_SECT */
    var n_desc: UInt16 { get } /* see <mach-o/stab.h> */
    var n_value: AddressType { get } /* value of this symbol (or stab offset) */
}

enum ReferenceType {
    init(value: UInt16) {
        switch(Int32(value)) {
        case REFERENCE_FLAG_UNDEFINED_NON_LAZY:
            self = UNDEFINED_NON_LAZY
            break
            
        case REFERENCE_FLAG_UNDEFINED_LAZY:
            self = UNDEFINED_LAZY
            break
            
        case REFERENCE_FLAG_DEFINED:
            self = DEFINED
            break
            
        case REFERENCE_FLAG_PRIVATE_DEFINED:
            self = PRIVATE_DEFINED
            break
            
        case REFERENCE_FLAG_PRIVATE_UNDEFINED_NON_LAZY:
            self = PRIVATE_UNDEFINED_NON_LAZY
            break
            
        case REFERENCE_FLAG_PRIVATE_UNDEFINED_LAZY:
            self = PRIVATE_UNDEFINED_LAZY
            break
            
        default:
            self = .Unknown(value: value)
            break
        }
    }
    case Unknown(value: UInt16)
    case UNDEFINED_NON_LAZY
    case UNDEFINED_LAZY
    case DEFINED
    case PRIVATE_DEFINED
    case PRIVATE_UNDEFINED_NON_LAZY
    case PRIVATE_UNDEFINED_LAZY
}
extension MachONlistType {
    var isExternal: Bool { return n_type & UInt8(N_EXT) != 0 }
    var isPrivateExternal: Bool { return n_type & UInt8(N_PEXT) != 0 }
    
    var symbolType: SymbolType {
        return SymbolType(value: self.n_type)
    }
    
    var referenceType: ReferenceType {
        return ReferenceType(value: self.n_desc & UInt16(REFERENCE_TYPE))
    }
    
    var isReferencedDynamically: Bool {
        return self.n_desc & UInt16(REFERENCED_DYNAMICALLY) != 0
    }
    
    var libraryOrdinal: Int {
        return Int(((n_desc) >> 8) & UInt16(0xff))
    }
    
    var isReferenceToWeak: Bool {
        return self.n_desc & UInt16(N_REF_TO_WEAK) != 0
    }
}

extension nlist_real : MachONlistType {
    typealias AddressType = UInt32
}

extension nlist_64_real : MachONlistType {
    typealias AddressType = UInt64
}


struct nlist_real {
    var n_strx: UInt32	/* index into the string table */
    var n_type: UInt8		/* type flag, see below */
    var n_sect: UInt8		/* section number or NO_SECT */
    var n_desc: UInt16		/* see <mach-o/stab.h> */
    var n_value: UInt32	/* value of this symbol (or stab offset) */
}

struct nlist_64_real {
    var n_strx: UInt32 /* index into the string table */
    var n_type: UInt8        /* type flag, see below */
    var n_sect: UInt8        /* section number or NO_SECT */
    var n_desc: UInt16       /* see <mach-o/stab.h> */
    var n_value: UInt64      /* value of this symbol (or stab offset) */
}

enum SymbolType {
    init(value: UInt8) {
        let type = Int32(value) & N_TYPE
        switch(type) {
        case N_UNDF:
            self = .UNDF
            return
        case N_ABS:
            self = .ABS
            return
        case N_SECT:
            self = .SECT
            return
            
        case N_PBUD:
            self = .PBUD
            return
        case N_INDR:
            self = .INDR
            return
            
        case 4:
            self = .FOUR
            return
            
        default:
            self = .Unknown(value: UInt8(type))
        }
    }
    case Unknown(value: UInt8)
    case UNDF
    case ABS
    case SECT
    case PBUD
    case INDR
    
    case FOUR // added because wtf
}



