//
//  MachOSegment.swift
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 12/4/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

public class MachOSegment {
    public let address: UnsafePointer<Void>
    public let size: UInt
    public let name: String!
    public let sections: [MachOSection]
    
    public init<T: MachOSegmentType>(command: UnsafePointer<T>, baseAddress: UnsafePointer<Void>) {
        self.address = baseAddress.advancedBy(Int(command.memory.fileoff.toIntMax()))
        self.size = UInt(command.memory.filesize.toIntMax())
        self.name = safeMachString(command.memory.segname)
        
        typealias SectionType = T.SectionType
        var sections = [MachOSection]()
        
        let csections = UnsafePointer<SectionType>(command.successor())
        let count = Int(command.memory.nsects)
        for i in 0 ..< count {
            sections.append(MachOSection(section: csections[i], baseAddress: baseAddress))
        }
        self.sections = sections
    }
    
    public func sectionNamed(name: String) -> MachOSection? {
        if let index = sections.indexOf({ $0.name == name }) {
            return sections[index]
        }
        return nil
    }
    
    public func sectionContainingAddress(address: UnsafePointer<Void>) -> MachOSection? {
        let diff = Int64(address - self.address)
        if diff < 0 || diff > Int64(self.size) {
            return nil
        }
        
        if let index = sections.indexOf({ $0.containsAddress(address) }) {
            return sections[index]
        }
        return nil
    }
}
