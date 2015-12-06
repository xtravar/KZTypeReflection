//
//  KZMachOSymbolTable.h
//  KZTypeReflection
//
//  Created by Mike Kasianowicz on 12/5/15.
//  Copyright © 2015 Mike Kasianowicz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KZMachOSymbolTable : NSObject
-(instancetype _Nullable )init;
-(instancetype _Nullable )initWithAddress:(const void* _Nonnull)address;
-(instancetype _Nonnull)initWithHeader:(const struct mach_header  *   _Nonnull)header;
@property (nonatomic, readonly)  NSString * _Nonnull moduleName;
@property (nonatomic, readonly)  NSString * _Nonnull modulePath;
-(void* _Nullable)pointerForSymbol:(NSString* _Nonnull) symbol NS_RETURNS_INNER_POINTER;
-(void)logSymbolsByName;
@end