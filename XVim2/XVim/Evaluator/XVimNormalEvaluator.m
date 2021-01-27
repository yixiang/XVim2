//
//  XVimNormalEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/19/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimNormalEvaluator.h"
#import "Logger.h"
#import "NSString+VimHelper.h"
#import "NSTextStorage+VimOperation.h"
#import "SourceEditorViewProtocol.h"
#import "XVim.h"
#import "XVimCommandLineEvaluator.h"
#import "XVimDeleteEvaluator.h"
#import "XVimEqualEvaluator.h"
#import "XVimEvaluator.h"
#import "XVimExCommand.h"
#import "XVimGActionEvaluator.h"
#import "XVimInsertEvaluator.h"
#import "XVimJoinEvaluator.h"
#import "XVimKeymapProvider.h"
#import "XVimMarkSetEvaluator.h"
#import "XVimMarks.h"
#import "XVimOptions.h"
#import "XVimRegisterManager.h"
#import "XVimRegisterEvaluator.h"
#import "XVimReplaceEvaluator.h"
#import "XVimReplacePromptEvaluator.h"
#import "XVimSearch.h"
#import "XVimShiftEvaluator.h"
#import "XVimTildeEvaluator.h"
#import "XVimVisualEvaluator.h"
#import "XVimWindow.h"
#import "XVimWindowEvaluator.h"
#import "XVimYankEvaluator.h"
#import "XVimKeyStroke.h"
#import "XVimRecordingEvaluator.h"
#import "XVim2-Swift.h"

@interface XVimNormalEvaluator () {
}
@end

@implementation XVimNormalEvaluator

- (id)initWithWindow:(XVimWindow*)window
{
    self = [super initWithWindow:window];
    if (self) {
    }
    return self;
}

- (void)becameHandler
{
    [super becameHandler];
}

- (NSString*)modeString { return @""; }

- (XVIM_MODE)mode { return XVIM_MODE_NORMAL; }

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider
{
    return [keymapProvider keymapForMode:XVIM_MODE_NORMAL];
}

/////////////////////////////////////////////////////////////////////////////////////////
// Keep command implementation alphabetical order please(Except specical characters).  //
/////////////////////////////////////////////////////////////////////////////////////////

- (XVimEvaluator*)a { return [[XVimInsertEvaluator alloc] initWithWindow:self.window insertMode:XVIM_INSERT_APPEND]; }

- (XVimEvaluator*)A { return [[XVimInsertEvaluator alloc] initWithWindow:self.window insertMode:XVIM_INSERT_APPEND_EOL]; }

// 'c' works like 'd' except that once it's done deleting
// it should go you into insert mode

// DELETE
#pragma mark - DELETE

- (XVimEvaluator*)c
{
    [self.argumentString appendString:@"c"];
    return [[XVimDeleteEvaluator alloc] initWithWindow:self.window insertModeAtCompletion:YES];
}

- (XVimEvaluator*)C
{
    // Same as c$
    let d = [[XVimDeleteEvaluator alloc] initWithWindow:self.window insertModeAtCompletion:YES];
    d.parent = self;
    return [d performSelector:@selector(DOLLAR)];
}

- (XVimEvaluator*)d
{
    // XVimOperatorAction *action = [[XVimDeleteAction alloc] initWithYankRegister:[self yankRegister]
    // insertModeAtCompletion:NO];
    [self.argumentString appendString:@"d"];
    return [[XVimDeleteEvaluator alloc] initWithWindow:self.window insertModeAtCompletion:FALSE];
}

- (XVimEvaluator*)D
{
    // Same as d$
    let eval = [[XVimDeleteEvaluator alloc] initWithWindow:self.window insertModeAtCompletion:NO];
    eval.parent = self;
    return [eval performSelector:@selector(DOLLAR)];
}

- (XVimEvaluator*)s
{
    // Same as cl
    let eval = [[XVimDeleteEvaluator alloc] initWithWindow:self.window insertModeAtCompletion:YES];
    eval.parent = self;
    return [eval performSelector:@selector(l)];
}

- (XVimEvaluator*)x
{
    // Same as dl
    let eval = [[XVimDeleteEvaluator alloc] initWithWindow:self.window insertModeAtCompletion:NO];
    eval.parent = self;
    return [eval performSelector:@selector(l)];
}

// like 'x" but it goes backwards instead of forwards
- (XVimEvaluator*)X
{
    let eval = [[XVimDeleteEvaluator alloc] initWithWindow:self.window insertModeAtCompletion:NO];
    eval.parent = self;
    return [eval performSelector:@selector(h)];
}

// "S" is Synonym for "cc"
- (XVimEvaluator*)S
{
    let d = [[XVimDeleteEvaluator alloc] initWithWindow:self.window insertModeAtCompletion:YES];
    d.parent = self;
    return [d performSelector:@selector(c)];
}

// UNDO/REDO
#pragma mark - UNDO/REDO

- (XVimEvaluator*)C_r
{
    let view = self.sourceView;
    for (NSUInteger i = 0; i < self.numericArg; i++) {
        [view.undoManager redo];
    }
    return nil;
}

- (XVimEvaluator*)u
{
    let view = self.sourceView;
    for (NSUInteger i = 0; i < self.numericArg; i++) {
        [view.undoManager undo];
    }
    return nil;
}

// SCROLL
// These are not motions but scrolling. That's the reason the implementation is here.
#pragma mark - SCROLL

- (XVimEvaluator*)C_b
{
    [self.sourceView xvim_scrollPageBackward:self.numericArg];
    return nil;
}

- (XVimEvaluator*)C_d
{
    [self.sourceView xvim_scrollHalfPageForward:self.numericArg];
    return nil;
}

- (XVimEvaluator*)C_e
{
    [self.sourceView xvim_scrollLineForward:self.numericArg];
    return nil;
}

- (XVimEvaluator*)C_u
{
    [self.sourceView xvim_scrollHalfPageBackward:self.numericArg];
    return nil;
}

- (XVimEvaluator*)C_f
{
    [self.sourceView xvim_scrollPageForward:self.numericArg];
    return nil;
}

- (XVimEvaluator*)C_y {
    [self.sourceView xvim_scrollLineBackward:self.numericArg];
    return nil;
}

// MOTION
#pragma mark - MOTION

- (XVimEvaluator*)g
{
    [self.argumentString appendString:@"g"];
    self.onChildCompleteHandler = @selector(onComplete_g:);
    return [[XVimGActionEvaluator alloc] initWithWindow:self.window];
}

- (XVimEvaluator*)i
{
    // Go to insert
    return [[XVimInsertEvaluator alloc] initWithWindow:self.window];
}

- (XVimEvaluator*)I
{
    return [[XVimInsertEvaluator alloc] initWithWindow:self.window insertMode:XVIM_INSERT_BEFORE_FIRST_NONBLANK];
}

- (XVimEvaluator*)onComplete_g:(XVimGActionEvaluator*)childEvaluator
{
    if (childEvaluator.key.selector == @selector(SEMICOLON)) {
        let mark = [XVim.instance.marks markForName:@"." forDocument:self.sourceView.documentURL.path];
        return [self jumpToMark:mark firstOfLine:NO KeepJumpMarkIndex:NO NeedUpdateMark:YES];
    }
    else {
        if (childEvaluator.motion != nil) {
            return [self _motionFixed:childEvaluator.motion];
        }
    }
    return nil;
}

- (XVimEvaluator*)o
{
    let view = [self sourceView];
    [view xvim_insertNewlineBelowAndInsertWithIndent];
    return [[XVimInsertEvaluator alloc] initWithWindow:self.window];
}

- (XVimEvaluator*)O
{
    let view = [self sourceView];
    [view xvim_insertNewlineAboveAndInsertWithIndent];
    return [[XVimInsertEvaluator alloc] initWithWindow:self.window];
}

// YANK
#pragma mark - YANK

- (XVimEvaluator*)Y
{
    let evaluator = [[XVimYankEvaluator alloc] initWithWindow:self.window];
    evaluator.numericArg = self.numericArg;
    [evaluator performSelector:@selector(y)];
    return nil;
}

- (XVimEvaluator*)y
{
    [self.argumentString appendString:@"y"];
    return [[XVimYankEvaluator alloc] initWithWindow:self.window];
}

// PUT
#pragma mark - PUT

- (XVimEvaluator*)p
{
    let view = self.sourceView;
    let reg = [XVim.instance.registerManager registerByName:self.yankRegister];
    [view xvim_put:reg.string type:reg.type afterCursor:YES count:self.numericArg];
    [[XVim instance] fixOperationCommands];
    return nil;
}

- (XVimEvaluator*)P
{
    let view = self.sourceView;
    let reg = [XVim.instance.registerManager registerByName:self.yankRegister];
    [view xvim_put:reg.string type:reg.type afterCursor:NO count:self.numericArg];
    [XVim.instance fixOperationCommands];
    return nil;
}


// REPLACE
#pragma mark - REPLACE


- (XVimEvaluator*)r
{
    [self.argumentString appendString:@"r"];
    return [[XVimReplaceEvaluator alloc] initWithWindow:self.window oneCharMode:YES insertMode:XVIM_INSERT_DEFAULT];
}

- (XVimEvaluator*)R
{
    [self.argumentString appendString:@"R"];
    return [[XVimReplaceEvaluator alloc] initWithWindow:self.window oneCharMode:NO insertMode:XVIM_INSERT_DEFAULT];
}


// SWAP CASE
#pragma mark - CASE

- (XVimEvaluator*)TILDE
{
    [self.argumentString appendString:@"~"];
    let swap = [[XVimTildeEvaluator alloc] initWithWindow:self.window];
    // TODO: support tildeop option
    return [swap fixWithNoMotion:self.numericArg];
}


// WINDOW
#pragma mark - WINDOW

- (XVimEvaluator*)C_w
{
    [self.argumentString appendString:@"^W"];
    return [[XVimWindowEvaluator alloc] initWithWindow:self.window];
}


// JOIN
#pragma mark - JOIN

- (XVimEvaluator*)J
{
    let eval = [[XVimJoinEvaluator alloc] initWithWindow:self.window addSpace:YES];
    return [eval executeOperationWithMotion:[XVimMotion style:MOTION_NONE type:CHARWISE_EXCLUSIVE count: self.numericArg]];
}


// SHIFT / INDENT
#pragma mark - SHIFT / INDENT

- (XVimEvaluator*)GREATERTHAN
{
    [self.argumentString appendString:@">"];
    let eval = [[XVimShiftEvaluator alloc] initWithWindow:self.window unshift:NO];
    return eval;
}

- (XVimEvaluator*)LESSTHAN
{
    [self.argumentString appendString:@"<"];
    let eval = [[XVimShiftEvaluator alloc] initWithWindow:self.window unshift:YES];
    return eval;
}

- (XVimEvaluator*)EQUAL
{
    [self.argumentString appendString:@"="];
    return [[XVimEqualEvaluator alloc] initWithWindow:self.window];
}


// VISUAL
#pragma mark - VISUAL


- (XVimEvaluator*)v
{
    if (XVim.instance.isProcessingDOT) {
        return [[XVimVisualEvaluator alloc] initWithLastVisualStateWithWindow:self.window];
    }
    else {
        return [[XVimVisualEvaluator alloc] initWithWindow:self.window mode:XVIM_VISUAL_CHARACTER];
    }
}

- (XVimEvaluator*)V
{
    if (XVim.instance.isProcessingDOT) {
        return [[XVimVisualEvaluator alloc] initWithLastVisualStateWithWindow:self.window];
    }
    else {
        return [[XVimVisualEvaluator alloc] initWithWindow:self.window mode:XVIM_VISUAL_LINE];
    }
}

- (XVimEvaluator*)C_v
{
    if (XVim.instance.isProcessingDOT) {
        return [[XVimVisualEvaluator alloc] initWithLastVisualStateWithWindow:self.window];
    }
    else {
        return [[XVimVisualEvaluator alloc] initWithWindow:self.window mode:XVIM_VISUAL_BLOCK];
    }
}


// MARK
#pragma mark - MARK

- (XVimEvaluator*)m
{
    // 'm{letter}' sets a local mark.
    [self.argumentString appendString:@"m"];
    return [[XVimMarkSetEvaluator alloc] initWithWindow:self.window];
}

- (XVimEvaluator*)C_o
{
    BOOL needUpdateMark;
    let mark = [XVim.instance.marks decrementJumpMark:&needUpdateMark];
    if (mark != nil) {
        [self jumpToMark:mark firstOfLine:NO KeepJumpMarkIndex:YES NeedUpdateMark:needUpdateMark];
    }
    return nil;
}

- (XVimEvaluator*)C_i
{
    let mark = [XVim.instance.marks incrementJumpMark];
    if (mark != nil) {
        [self jumpToMark:mark firstOfLine:NO KeepJumpMarkIndex:YES NeedUpdateMark:NO];
    }
    return nil;
}


// OTHERS

- (XVimEvaluator*)C_RSQUAREBRACKET
{
    // Add current position/file to jump list
    let motion = [XVimMotion style:MOTION_POSITION_JUMP type:DEFAULT_MOTION_TYPE count:0];
    motion.jumpToAnotherFile = YES;
    [self.window preMotion:motion];

    [NSApp sendAction:NSSelectorFromString(@"jumpToDefinition:") to:nil from:self];
    return nil;
}


// COMMAND-LINE

- (XVimEvaluator*)COLON
{
    __block XVimEvaluator* eval = [[XVimCommandLineEvaluator alloc]
                initWithWindow:self.window
                   firstLetter:@":"
                       history:XVim.instance.exCommandHistory
                    completion:^XVimEvaluator*(NSString* command, XVimMotion** result) {
                        let excmd = XVim.instance.excmd;
                        let commandExecuted = [excmd executeCommand:command inWindow:self.window];

                        if ([commandExecuted isEqualToString:@"substitute"]) {
                            let searcher = XVim.instance.searcher;
                            if (searcher.confirmEach && searcher.lastFoundRange.location != NSNotFound) {
                                [eval didEndHandler];
                                return [[XVimReplacePromptEvaluator alloc]
                                               initWithWindow:self.window
                                            replacementString:searcher.lastReplacementString];
                            }
                        }
                        return nil;
                    }
                    onKeyPress:nil];

    return eval;
}

// TAGS / HISTORY
#pragma mark - TAGS / HISTORY

- (XVimEvaluator*)C_t
{
    xvim_ignore_warning_undeclared_selector_push
                [NSApp sendAction:@selector(goBackInHistoryByCommand:) to:nil from:self];
    xvim_ignore_warning_pop return nil;
}

// INCREMENT / DECREMENT
#pragma mark - INCREMENT / DECREMENT

- (XVimEvaluator*)C_a
{
    let view = self.sourceView;
    if ([view xvim_incrementNumber:(int64_t)self.numericArg]) {
        [XVim.instance fixOperationCommands];
    }
    else {
        [XVim.instance cancelOperationCommands];
    }
    return nil;
}

- (XVimEvaluator*)C_x
{
    let view = self.sourceView;

    if ([view xvim_incrementNumber:-(int64_t)self.numericArg]) {
        [XVim.instance fixOperationCommands];
    }
    else {
        [XVim.instance cancelOperationCommands];
    }
    return nil;
}



// Should be moved to XVimMotionEvaluator
- (XVimEvaluator*)q{
    if( XVim.instance.isExecuting ){
        return nil;
    }
    [self.argumentString appendString:@"q"];
    XVimEvaluator* e = [[XVimRegisterEvaluator alloc] initWithWindow:self.window];
    self.onChildCompleteHandler = @selector(onComplete_q:);
    return e;
}

- (XVimEvaluator*)onComplete_q:(XVimRegisterEvaluator*)childEvaluator{
    if( [XVim.instance.registerManager isValidForRecording:childEvaluator.reg] ){
        self.onChildCompleteHandler = @selector(onComplete_Recording:);
        return [[XVimRecordingEvaluator alloc] initWithWindow:self.window withRegister:childEvaluator.reg];
    }
    [XVim.instance ringBell];
    return nil;
}

- (XVimEvaluator*)onComplete_Recording:childEvaluator{
    return nil;
}

- (XVimEvaluator*)AT{
    if( XVim.instance.isExecuting ){
        return nil;
    }
    [self.argumentString appendString:@"@"];
    XVimEvaluator *eval = [[XVimRecordingRegisterEvaluator alloc] initWithWindow:self.window];
    self.onChildCompleteHandler = @selector(onComplete_AT:);
    return eval;
}

- (XVimEvaluator*)onComplete_AT:(XVimRecordingRegisterEvaluator*)childEvaluator{
    self.onChildCompleteHandler = @selector(onChildComplete:);
    XVimRegister* reg = [XVim.instance.registerManager registerByName:childEvaluator.reg];

    XVim.instance.isExecuting = YES;
    NSUInteger count = self.numericArg;
    [self resetNumericArg];
    for( NSUInteger repeat = 0 ; repeat < count; repeat++ ){
        for( XVimKeyStroke* stroke in XVimKeyStrokesFromXVimString(reg.string) ){
            [self.window handleKeyStroke:stroke onStack:nil];
        }
    }
    [XVim.instance.registerManager registerExecuted:childEvaluator.reg];
    XVim.instance.isExecuting = NO;
    return [XVimEvaluator noOperationEvaluator];
}




#if 0


- (XVimEvaluator*)HT{
    [self.sourceView xvim_selectNextPlaceholder];
    return nil;
}
#endif

// REGISTER
#pragma mark - REGISTER
- (XVimEvaluator*)DQUOTE
{
    [self.argumentString appendString:@"\""];
    self.onChildCompleteHandler = @selector(onComplete_DQUOTE:);
    return [[XVimRegisterEvaluator alloc] initWithWindow:self.window];
}

- (XVimEvaluator*)onComplete_DQUOTE:(XVimRegisterEvaluator*)childEvaluator
{
    let m = XVim.instance.registerManager;
    if ([m isValidRegister:childEvaluator.reg]) {
        self.yankRegister = childEvaluator.reg;
        [self.argumentString appendString:childEvaluator.reg];
        self.onChildCompleteHandler = @selector(onChildComplete:);
        return self;
    }
    else {
        return [XVimEvaluator invalidEvaluator];
    }
}

- (XVimEvaluator*)DOT
{
    [XVim.instance startDOT];
    [self.sourceView xvim_beginEditTransaction];
    xvim_on_exit { [self.sourceView xvim_endEditTransaction]; };

    let repeatRegister = XVim.instance.lastOperationCommands;

    var stack = [NSMutableArray<XVimEvaluator*> new];

    if (self.numericMode) {
        // Input numeric args if dot command has numeric arg
        XVimString* nums = [NSString stringWithFormat:@"%ld", (unsigned long)self.numericArg];
        for (XVimKeyStroke* stroke in XVimKeyStrokesFromXVimString(nums)) {
            [self.window handleKeyStroke:stroke onStack:stack];
        }
    }

    var nonNumFound = NO;
    for (XVimKeyStroke* stroke in XVimKeyStrokesFromXVimString(repeatRegister)) {
        // TODO: This skips numeric args in repeat regisger if numericArg is specified.
        //       But if numericArg is not begining of the input (such as d3w) this never skips it.
        //       We have to also correctly handle "df3" not to skip the number.
        if (!nonNumFound && self.numericMode && stroke.isNumeric) {
            // Skip numeric arg
            continue;
        }
        nonNumFound = YES;
        [self.window handleKeyStroke:stroke onStack:stack];
    }
    [XVim.instance endDOT];
    return nil;
}


- (XVimEvaluator*)C_g
{
    // process
    let window = self.window;
    let range = window.sourceView.selectedRange;
    let numberOfLines = [window.sourceView.textStorage xvim_numberOfLines];
    let lineNumber = window.sourceView.currentLineNumber;
    let columnNumber = [window.sourceView.textStorage xvim_columnOfIndex:range.location];
    let documentURL = window.sourceView.documentURL;
    if (documentURL.isFileURL) {
        NSString* filename = [documentURL path];
        NSString* text = [NSString
                    stringWithFormat:@"%@   line %ld of %ld --%d%%-- col %ld", filename, lineNumber, numberOfLines,
                                     (int)((float)lineNumber * 100.0 / (float)numberOfLines), columnNumber + 1];

        [window statusMessage:text];
       [self openLineInCS:documentURL lineNumber:lineNumber];
    }
    return nil;
}

- (void)openLineInCS:(NSURL *)fileURL lineNumber:(long long)lineNumber {
  NSString *depotPath = [self depotPathFromLocalPath:fileURL.path];
  if (depotPath == nil) {
    return;
  }
  NSURL *csURL = [self csURLForFileWithDepotPath:depotPath line:(NSUInteger)lineNumber];
  if (csURL == nil) {
    return;
  }
  [[NSWorkspace sharedWorkspace] openURL:csURL];
}

- (NSString *)depotPathFromLocalPath:(NSString *)localPath {
  NSRange rangeOfGoogle3 = [localPath rangeOfString:@"google3"];
  if (rangeOfGoogle3.location == NSNotFound) {
    return nil;
  }
  NSString *google3 = [localPath substringFromIndex:rangeOfGoogle3.location];
  NSString *depotPath = [NSString stringWithFormat:@"//depot/%@", google3];
  return depotPath;
}

- (NSURL *)csURLForFileWithDepotPath:(NSString *)depotPath line:(NSUInteger)line {
  static NSString *const kCsHost = @"https://cs.corp.google.com";
  NSString *csURLString = [NSString stringWithFormat:@"%@/#piper/%@&l=%tu", kCsHost, depotPath, line];
  NSURL *csURL = [NSURL URLWithString:csURLString];
  return csURL;
}

- (XVimEvaluator*)ForwardDelete { return [self x]; }

- (XVimEvaluator*)Pageup { return [self C_b]; }

- (XVimEvaluator*)Pagedown { return [self C_f]; }

- (XVimEvaluator*)motionFixedCore:(XVimMotion*)motion
{
    [self.window preMotion:motion];
    [self.sourceView xvim_move:motion];
    return nil;
}

@end
