//
//  MachOBindEntry.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 12/4/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

import Foundation
import MachO

public struct MachOBindEntry {
    public var segmentIndex = Int()
    public var flags = Int()
    public var offset = UInt()
    public var type = Int()
    public var libraryOrdinal = Int()
    public var symbolName = String()
    public var addend = Int64()
    public var weakImport: Bool { return (self.flags & Int(BIND_SYMBOL_FLAGS_WEAK_IMPORT)) != 0 }
    public var nonWeakDefinition: Bool { return (self.flags & Int(BIND_SYMBOL_FLAGS_NON_WEAK_DEFINITION)) != 0}
    
    public static func entriesFromStream(stream: NSInputStream, pointerSize: Int) -> [MachOBindEntry] {
        // <seg-index, seg-offset, type, symbol-library-ordinal, symbol-name, addend>
        var retval = [MachOBindEntry]()
        var entry = MachOBindEntry()
        
        var byte = UInt8()
        for(;;) {
            let readLength = stream.read(&byte, maxLength: sizeof(UInt8.self))
            // depending, I presume, on alignment, you can get a DONE or EOF
            if readLength != 1 {
                return retval
            }
            
            let opcode: Int32 = Int32(byte) & BIND_OPCODE_MASK
            var imm: Int32 = Int32(byte) & BIND_IMMEDIATE_MASK
            
            // sNSLog(@"opcode %x", (int)opcode)
            switch(opcode) {
            case BIND_OPCODE_SET_DYLIB_ORDINAL_IMM:
                entry.libraryOrdinal = Int(imm)
                break
                
            case BIND_OPCODE_SET_DYLIB_ORDINAL_ULEB:
                entry.libraryOrdinal = Int(stream.readULEB128())
                break
                
            case BIND_OPCODE_SET_DYLIB_SPECIAL_IMM:
                if(imm != 0) {
                    imm = imm | BIND_OPCODE_MASK
                }
                entry.libraryOrdinal = Int(imm)
                break
                
            case BIND_OPCODE_SET_SYMBOL_TRAILING_FLAGS_IMM:
                entry.flags = Int(imm)
                entry.symbolName = stream.readCString()
                break
                
            case BIND_OPCODE_SET_TYPE_IMM:
                precondition(imm == BIND_TYPE_POINTER, "non-pointer binding not supported")
                entry.type = Int(imm)
                break
                
            case BIND_OPCODE_SET_ADDEND_SLEB:
                preconditionFailure("Bind code unsupported")
                break
                
            case BIND_OPCODE_SET_SEGMENT_AND_OFFSET_ULEB:
                entry.segmentIndex = Int(imm)
                entry.offset = stream.readULEB128()
                break
                
            case BIND_OPCODE_ADD_ADDR_ULEB:
                entry.offset += stream.readULEB128()
                break
                
            case BIND_OPCODE_DO_BIND:
                retval.append(entry)
                entry.offset += UInt(pointerSize)
                break
                
            case BIND_OPCODE_DO_BIND_ADD_ADDR_ULEB:
                retval.append(entry)
                entry.offset += stream.readULEB128() + UInt(pointerSize)
                break
                
            case BIND_OPCODE_DO_BIND_ADD_ADDR_IMM_SCALED:
                retval.append(entry)
                entry.offset += UInt(Int(imm) * pointerSize + pointerSize)
                break
                
            case BIND_OPCODE_DO_BIND_ULEB_TIMES_SKIPPING_ULEB:
                let count = stream.readULEB128()
                let skip = stream.readULEB128()
                for _ in 0 ..< count {
                    retval.append(entry)
                    entry.offset += UInt(pointerSize)
                    entry.offset += skip
                }
                break
                
                
            case BIND_OPCODE_DONE:
                return retval
                
            default:
                preconditionFailure("Bind code unsupported")
                break
            }
        }
    }
    
}

private extension NSInputStream {
    @nonobjc func readULEB128() -> UInt {
        var retval = UInt()
        var shift = UInt()
        
        var byte = UInt8()
        for(;;) {
            let readValue = self.read(&byte, maxLength: sizeof(UInt8.self))
            precondition(readValue == 1, "unexpected end of stream")
            
            let k = UInt(byte & 0x7F)
            if shift < UInt(sizeof(UInt.self)) * 8 {
                retval |= ( k << shift)
            }
            
            if (byte & 0x80) == 0 {
                break
            }
            
            shift += 7
            precondition(shift < 64, "encoded int too long")
        }
        
        return retval
    }
    
    @nonobjc func readCString() -> String {
        var retval = String()
        var byte = UInt8()
        for(;;) {
            let readValue = self.read(&byte, maxLength: sizeof(UInt8.self))
            precondition(readValue == 1, "unexpected end of stream")
            
            if byte == 0 {
                break
            }
            
            retval.append(UnicodeScalar(byte))
        }
        return retval
    }
}