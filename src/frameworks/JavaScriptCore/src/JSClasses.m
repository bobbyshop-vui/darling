// Objective-C classes of the JavaScriptCore stub. They exist so binaries that
// reference them link; no scripting engine is behind them.
#import <Foundation/Foundation.h>

@interface JSVirtualMachine : NSObject
@end

@implementation JSVirtualMachine
@end

@interface JSContext : NSObject {
	JSVirtualMachine *_virtualMachine;
}
- (instancetype) init;
- (instancetype) initWithVirtualMachine: (JSVirtualMachine *) virtualMachine;
- (JSVirtualMachine *) virtualMachine;
@end

@implementation JSContext

- (instancetype) init
{
	return [self initWithVirtualMachine: [[[JSVirtualMachine alloc] init] autorelease]];
}

- (instancetype) initWithVirtualMachine: (JSVirtualMachine *) virtualMachine
{
	if ((self = [super init]))
		_virtualMachine = [virtualMachine retain];
	return self;
}

- (void) dealloc
{
	[_virtualMachine release];
	[super dealloc];
}

- (JSVirtualMachine *) virtualMachine
{
	return _virtualMachine;
}

@end

@interface JSValue : NSObject {
	JSContext *_context;
}
- (JSContext *) context;
@end

@implementation JSValue

- (JSContext *) context
{
	return _context;
}

@end
