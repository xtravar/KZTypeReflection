//
//  MachOLinkerCommands.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 12/8/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation
import MachO

extension dylib_command : MachOLoadCommandType {
}

extension dyld_info_command : MachOLoadCommandType {
}

extension symtab_command : MachOLoadCommandType {
}

extension dysymtab_command : MachOLoadCommandType {
}


extension segment_command: MachOLoadCommandType {
}


extension segment_command_64: MachOLoadCommandType {
}

extension version_min_command: MachOLoadCommandType {
}

extension linkedit_data_command: MachOLoadCommandType {
}

extension routines_command_64: MachOLoadCommandType {
}

extension uuid_command: MachOLoadCommandType {
}
extension encryption_info_command_64: MachOLoadCommandType {
}

extension linker_option_command: MachOLoadCommandType {
}
extension dylinker_command: MachOLoadCommandType {
}

extension source_version_command: MachOLoadCommandType {
}
extension symseg_command: MachOLoadCommandType {}

extension sub_client_command: MachOLoadCommandType {
}

extension thread_command: MachOLoadCommandType {}

extension fvmlib_command: MachOLoadCommandType {}
extension ident_command: MachOLoadCommandType {}

extension fvmfile_command: MachOLoadCommandType {}
extension load_command: MachOLoadCommandType {}
extension prebound_dylib_command: MachOLoadCommandType {}
extension routines_command: MachOLoadCommandType {}
extension sub_framework_command: MachOLoadCommandType {}
extension sub_umbrella_command: MachOLoadCommandType {}
extension sub_library_command: MachOLoadCommandType {}
extension twolevel_hints_command: MachOLoadCommandType {}
extension encryption_info_command: MachOLoadCommandType {}
extension prebind_cksum_command: MachOLoadCommandType {}

struct LoadCommand {
    let identifier: Int
    let type: MachOLoadCommandType.Type
    
    init(_ identifier: Int32, _ type: MachOLoadCommandType.Type) {
        self.identifier = Int(identifier)
        self.type = type
    }
    init(_ identifier: UInt32, _ type: MachOLoadCommandType.Type) {
        self.identifier = Int(identifier)
        self.type = type
    }
    
    
    static let SEGMENT = LoadCommand(LC_SEGMENT, segment_command.self)
    static let SYMTAB = LoadCommand(LC_SYMTAB, symtab_command.self)
    static let SYMSEG = LoadCommand(LC_SYMSEG, symseg_command.self)
    static let THREAD = LoadCommand(LC_THREAD, thread_command.self)
    static let UNIXTHREAD = LoadCommand(LC_UNIXTHREAD, thread_command.self)
    static let LOADFVMLIB = LoadCommand(LC_LOADFVMLIB, fvmlib_command.self)
    static let IDFVMLIB = LoadCommand(LC_IDFVMLIB, fvmlib_command.self)
    static let IDENT = LoadCommand(LC_IDENT, ident_command.self)
    static let FVMFILE = LoadCommand(LC_FVMFILE, fvmfile_command.self)
    static let PREPAGE = LoadCommand(LC_PREPAGE, load_command.self)
    static let DYSYMTAB = LoadCommand(LC_DYSYMTAB, dysymtab_command.self)
    static let LOAD_DYLIB = LoadCommand(LC_LOAD_DYLIB, dylib_command.self)
    static let ID_DYLIB = LoadCommand(LC_ID_DYLIB, dylib_command.self)
    static let LOAD_DYLINKER = LoadCommand(LC_LOAD_DYLINKER, dylinker_command.self)
    static let ID_DYLINKER = LoadCommand(LC_ID_DYLINKER, dylinker_command.self)
    static let PREBOUND_DYLIB = LoadCommand(LC_PREBOUND_DYLIB, prebound_dylib_command.self)
    static let ROUTINES = LoadCommand(LC_ROUTINES, routines_command.self)
    static let SUB_FRAMEWORK = LoadCommand(LC_SUB_FRAMEWORK, sub_framework_command.self)
    static let SUB_UMBRELLA = LoadCommand(LC_SUB_UMBRELLA, sub_umbrella_command.self)
    static let SUB_CLIENT = LoadCommand(LC_SUB_CLIENT, sub_client_command.self)
    static let SUB_LIBRARY = LoadCommand(LC_SUB_LIBRARY, sub_library_command.self)
    static let TWOLEVEL_HINTS = LoadCommand(LC_TWOLEVEL_HINTS, twolevel_hints_command.self)
    static let PREBIND_CKSUM = LoadCommand(LC_PREBIND_CKSUM, prebind_cksum_command.self)
    static let SEGMENT_64 = LoadCommand(LC_SEGMENT_64, segment_command_64.self)
    static let ROUTINES_64 = LoadCommand(LC_ROUTINES_64, routines_command_64.self)
    static let UUID = LoadCommand(LC_UUID, uuid_command.self)
    static let CODE_SIGNATURE = LoadCommand(LC_CODE_SIGNATURE, linkedit_data_command.self)
    static let SEGMENT_SPLIT_INFO = LoadCommand(LC_SEGMENT_SPLIT_INFO, linkedit_data_command.self)
    static let LAZY_LOAD_DYLIB = LoadCommand(LC_LAZY_LOAD_DYLIB, dylib_command.self)
    static let ENCRYPTION_INFO = LoadCommand(LC_ENCRYPTION_INFO, encryption_info_command.self)
    static let DYLD_INFO = LoadCommand(LC_DYLD_INFO, dyld_info_command.self)
    static let VERSION_MIN_MACOSX = LoadCommand(LC_VERSION_MIN_MACOSX, version_min_command.self)
    static let VERSION_MIN_IPHONEOS = LoadCommand(LC_VERSION_MIN_IPHONEOS, version_min_command.self)
    static let FUNCTION_STARTS = LoadCommand(LC_FUNCTION_STARTS, linkedit_data_command.self)
    static let DYLD_ENVIRONMENT = LoadCommand(LC_DYLD_ENVIRONMENT, dylinker_command.self)
    static let DATA_IN_CODE = LoadCommand(LC_DATA_IN_CODE, linkedit_data_command.self)
    static let SOURCE_VERSION = LoadCommand(LC_SOURCE_VERSION, source_version_command.self)
    static let DYLIB_CODE_SIGN_DRS = LoadCommand(LC_DYLIB_CODE_SIGN_DRS, linkedit_data_command.self)
    static let ENCRYPTION_INFO_64 = LoadCommand(LC_ENCRYPTION_INFO_64, encryption_info_command_64.self)
    static let LINKER_OPTION = LoadCommand(LC_LINKER_OPTION, linker_option_command.self)
    static let LINKER_OPTIMIZATION_HINT = LoadCommand(LC_LINKER_OPTIMIZATION_HINT, linkedit_data_command.self)
    static let VERSION_MIN_TVOS = LoadCommand(LC_VERSION_MIN_TVOS, version_min_command.self)
    static let VERSION_MIN_WATCHOS = LoadCommand(LC_VERSION_MIN_WATCHOS, version_min_command.self)
}

enum LoadCommandType {
    init(value: Int32) {
        self.init(value: Int(value))
    }
    
    init(value: UInt32) {
        self.init(value: Int(value))
    }
    
    init(value: Int) {
        switch(value) {
        case LoadCommand.SEGMENT.identifier:
            self = SEGMENT
            break
        case LoadCommand.SYMTAB.identifier:
            self = SYMTAB
            break
        case LoadCommand.SYMSEG.identifier:
            self = SYMSEG
            break
        case LoadCommand.THREAD.identifier:
            self = THREAD
            break
        case LoadCommand.UNIXTHREAD.identifier:
            self = UNIXTHREAD
            break
        case LoadCommand.LOADFVMLIB.identifier:
            self = LOADFVMLIB
            break
        case LoadCommand.IDFVMLIB.identifier:
            self = IDFVMLIB
            break
        case LoadCommand.IDENT.identifier:
            self = IDENT
            break
        case LoadCommand.FVMFILE.identifier:
            self = FVMFILE
            break
        case LoadCommand.PREPAGE.identifier:
            self = PREPAGE
            break
        case LoadCommand.DYSYMTAB.identifier:
            self = DYSYMTAB
            break
        case LoadCommand.LOAD_DYLIB.identifier:
            self = LOAD_DYLIB
            break
        case LoadCommand.ID_DYLIB.identifier:
            self = ID_DYLIB
            break
        case LoadCommand.LOAD_DYLINKER.identifier:
            self = LOAD_DYLINKER
            break
        case LoadCommand.ID_DYLINKER.identifier:
            self = ID_DYLINKER
            break
        case LoadCommand.PREBOUND_DYLIB.identifier:
            self = PREBOUND_DYLIB
            break
        case LoadCommand.ROUTINES.identifier:
            self = ROUTINES
            break
        case LoadCommand.SUB_FRAMEWORK.identifier:
            self = SUB_FRAMEWORK
            break
        case LoadCommand.SUB_UMBRELLA.identifier:
            self = SUB_UMBRELLA
            break
        case LoadCommand.SUB_CLIENT.identifier:
            self = SUB_CLIENT
            break
        case LoadCommand.SUB_LIBRARY.identifier:
            self = SUB_LIBRARY
            break
        case LoadCommand.TWOLEVEL_HINTS.identifier:
            self = TWOLEVEL_HINTS
            break
        case LoadCommand.PREBIND_CKSUM.identifier:
            self = PREBIND_CKSUM
            break
        case LoadCommand.SEGMENT_64.identifier:
            self = SEGMENT_64
            break
        case LoadCommand.ROUTINES_64.identifier:
            self = ROUTINES_64
            break
        case LoadCommand.UUID.identifier:
            self = UUID
            break
        case LoadCommand.CODE_SIGNATURE.identifier:
            self = CODE_SIGNATURE
            break
        case LoadCommand.SEGMENT_SPLIT_INFO.identifier:
            self = SEGMENT_SPLIT_INFO
            break
        case LoadCommand.LAZY_LOAD_DYLIB.identifier:
            self = LAZY_LOAD_DYLIB
            break
        case LoadCommand.ENCRYPTION_INFO.identifier:
            self = ENCRYPTION_INFO
            break
        case LoadCommand.DYLD_INFO.identifier:
            self = DYLD_INFO
            break
        case LoadCommand.VERSION_MIN_MACOSX.identifier:
            self = VERSION_MIN_MACOSX
            break
        case LoadCommand.VERSION_MIN_IPHONEOS.identifier:
            self = VERSION_MIN_IPHONEOS
            break
        case LoadCommand.FUNCTION_STARTS.identifier:
            self = FUNCTION_STARTS
            break
        case LoadCommand.DYLD_ENVIRONMENT.identifier:
            self = DYLD_ENVIRONMENT
            break
        case LoadCommand.DATA_IN_CODE.identifier:
            self = DATA_IN_CODE
            break
        case LoadCommand.SOURCE_VERSION.identifier:
            self = SOURCE_VERSION
            break
        case LoadCommand.DYLIB_CODE_SIGN_DRS.identifier:
            self = DYLIB_CODE_SIGN_DRS
            break
        case LoadCommand.ENCRYPTION_INFO_64.identifier:
            self = ENCRYPTION_INFO_64
            break
        case LoadCommand.LINKER_OPTION.identifier:
            self = LINKER_OPTION
            break
        case LoadCommand.LINKER_OPTIMIZATION_HINT.identifier:
            self = LINKER_OPTIMIZATION_HINT
            break
        case LoadCommand.VERSION_MIN_TVOS.identifier:
            self = VERSION_MIN_TVOS
            break
        case LoadCommand.VERSION_MIN_WATCHOS.identifier:
            self = VERSION_MIN_WATCHOS
            break
        default:
            self = UNKNOWN(identifier: value)
        }
    }
    
    case UNKNOWN(identifier: Int)
    
    case SEGMENT
    case SYMTAB
    case SYMSEG
    case THREAD
    case UNIXTHREAD
    case LOADFVMLIB
    case IDFVMLIB
    case IDENT
    case FVMFILE
    case PREPAGE
    case DYSYMTAB
    case LOAD_DYLIB
    case ID_DYLIB
    case LOAD_DYLINKER
    case ID_DYLINKER
    case PREBOUND_DYLIB
    case ROUTINES
    case SUB_FRAMEWORK
    case SUB_UMBRELLA
    case SUB_CLIENT
    case SUB_LIBRARY
    case TWOLEVEL_HINTS
    case PREBIND_CKSUM
    case SEGMENT_64
    case ROUTINES_64
    case UUID
    case CODE_SIGNATURE
    case SEGMENT_SPLIT_INFO
    case LAZY_LOAD_DYLIB
    case ENCRYPTION_INFO
    case DYLD_INFO
    case VERSION_MIN_MACOSX
    case VERSION_MIN_IPHONEOS
    case FUNCTION_STARTS
    case DYLD_ENVIRONMENT
    case DATA_IN_CODE
    case SOURCE_VERSION
    case DYLIB_CODE_SIGN_DRS
    case ENCRYPTION_INFO_64
    case LINKER_OPTION
    case LINKER_OPTIMIZATION_HINT
    case VERSION_MIN_TVOS
    case VERSION_MIN_WATCHOS
    
}