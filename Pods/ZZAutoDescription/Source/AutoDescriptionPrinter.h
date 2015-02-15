//
//  AutoDescriptionPrinter.h
//  iHerb
//
//  Created by Ivan Zezyulya on 15.04.14.
//  Copyright (c) 2014 aldigit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AutoDescriptionPrinter : NSObject

- (void) increaseIndent;

/// Same as calling printIndent, printText:line, and printNewLine
- (void) printLine:(NSString *)line;

- (void) printIndent;
- (void) printText:(NSString *)text;
- (void) printNewLine;

- (void) decreaseIndent;

- (NSString *) result;

/// Default is 2.
@property (nonatomic) NSInteger indentSpaces;

/// Helps to avoid recursion if printed object graph has cycles.
/// Call after calling printLine:.
- (void) pushPrintedObject:(id)printedObject;
- (void) popPrintedObject:(id)printedObject;
- (BOOL) isObjectInPrintedStack:(id)object;

@property (nonatomic, readonly) NSInteger currentIndentLevel;

@end
