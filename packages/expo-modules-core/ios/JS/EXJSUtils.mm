#import <ExpoModulesCore/EXJSUtils.h>
#import <ExpoModulesCore/NativeModule.h>
#import <ExpoModulesCore/EventEmitter.h>

@implementation EXJSUtils

//+ (void)emitEvent:(nonnull NSString *)eventName
//         toObject:(nonnull EXJavaScriptObject *)object
//    withArguments:(nonnull NSArray<id> *)arguments
//        inRuntime:(nonnull EXJavaScriptRuntime *)runtime
//{
//  const std::vector<jsi::Value> argumentsVector(expo::convertNSArrayToStdVector(*[runtime get], arguments));
//  expo::EventEmitter::emitEvent(*[runtime get], *[object get], [eventName UTF8String], std::move(argumentsVector));
//}

@end
