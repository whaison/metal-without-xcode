#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#import <simd/simd.h>
#import "common.h"
#import <Foundation/NSObject.h>
#import <stdio.h>

@interface HelloMetalView : MTKView
@property NSString *sampleStr;
@property int sampleInt;
@property float sampleFloat;
@property BOOL sampleBool;


@end

int main () {
    NSLog(@"main()");
    @autoreleasepool {
        NSLog(@"autoreleasepool()");
        // Application.
        [NSApplication sharedApplication];
        [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
        [NSApp activateIgnoringOtherApps:YES];

        // Menu.
        NSMenu* bar = [NSMenu new];
        NSMenuItem * barItem = [NSMenuItem new];
        NSMenu* menu = [NSMenu new];
        NSMenuItem* quit = [[NSMenuItem alloc]
                               initWithTitle:@"Quit"
                               action:@selector(terminate:)
                               keyEquivalent:@"q"];
        [bar addItem:barItem];
        [barItem setSubmenu:menu];
        [menu addItem:quit];
        NSApp.mainMenu = bar;

        NSRect rect = NSMakeRect(0, 0, 256, 256);
        // Window.
        NSRect frame = NSMakeRect(0, 0, 256, 256);
        NSWindow* window = [[NSWindow alloc] 
                                initWithContentRect:rect
                                styleMask:NSWindowStyleMaskTitled
                                backing:NSBackingStoreBuffered
                                defer:NO];
        [window cascadeTopLeftFromPoint:NSMakePoint(20,20)];
        window.styleMask |= NSWindowStyleMaskResizable;
        window.styleMask |= NSWindowStyleMaskMiniaturizable ;
        window.styleMask |= NSWindowStyleMaskClosable;
        window.title = [[NSProcessInfo processInfo] processName];
        [window makeKeyAndOrderFront:nil];

        // Custom MTKView.
        HelloMetalView* view = [[HelloMetalView alloc] initWithFrame:frame];
        window.contentView = view;

        // Run.
        [NSApp run];
        NSLog(@"run()");
    }
    return 0;
}

// Vertex structure on CPU memory.
struct Vertex {
    /////////////////////////
    //float position[3];
    //float position[4];
    float position[6];
    ///////////////////////
    unsigned char color[4];
};

// For pipeline executing.
/////////////////////////////////////////
//constexpr int uniformBufferCount = 3;
constexpr int uniformBufferCount = 4;
////////////////////////////////////////
/*
@implementation ViewController
- (void)viewDidLoad
{
    [self mainfunc];
    //[self debugStr];
    //[self debugInt];
    //[self debugBool];
}
*/
// The main view.
@implementation HelloMetalView {
    id <MTLLibrary> _library;
    id <MTLCommandQueue> _commandQueue;
    id <MTLRenderPipelineState> _pipelineState;
    id <MTLDepthStencilState> _depthState;
    dispatch_semaphore_t _semaphore;
    id <MTLBuffer> _resorutionBuffer;
    id <MTLBuffer> _uniformBuffers[uniformBufferCount];
    id <MTLBuffer> _vertexBuffer;
    int uniformBufferIndex;
    long frame;

}



- (id)initWithFrame:(CGRect)inFrame {
    NSLog(@"initWithFrame()");
    id<MTLDevice> device = MTLCreateSystemDefaultDevice();
    self = [super initWithFrame:inFrame device:device];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup {
    NSLog(@"setup()");

    [self mainfunc];
    [self debugStr];
    [self debugInt];
    [self debugBool];

    // Set view settings.
    self.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    self.depthStencilPixelFormat = MTLPixelFormatDepth32Float_Stencil8;

    // Load shaders.
    NSError *error = nil;


    _library = [self.device newLibraryWithFile: @"shaders.metallib" error:&error];
    //_library = self.device newLibraryWithFile(@"shaders.metallib",error);
    //_library = makeLibrary(@"./shaders.metallib");
    //_library = [self.device makeLibrary: @"./shaders.metallib" error:&error];
    //typealias MTLNewLibraryCompletionHandler = (MTLLibrary?, Error?) -> Void

    if (!_library) {
        NSLog(@"Failed to load (shaders.metallib)library. error ===== %@", error);
        exit(0);
    }else{
        NSLog(@"setup().Loaded....shaders.metallib");
    }
    id <MTLFunction> vertFunc = [_library newFunctionWithName:@"vert"];
    id <MTLFunction> fragFunc = [_library newFunctionWithName:@"frag"];

    // Create depth state.
    MTLDepthStencilDescriptor *depthDesc = [MTLDepthStencilDescriptor new];
    depthDesc.depthCompareFunction = MTLCompareFunctionLess;
    depthDesc.depthWriteEnabled = YES;
    _depthState = [self.device newDepthStencilStateWithDescriptor:depthDesc];

    // Create vertex descriptor.
    MTLVertexDescriptor *vertDesc = [MTLVertexDescriptor new];
    //////////////////////////////////////////////////////////////////////
    //vertDesc.attributes[VertexAttributePosition].format = MTLVertexFormatFloat3;
    vertDesc.attributes[VertexAttributePosition].format = MTLVertexFormatFloat4;
    //////////////////////////////////////////////////////////////////////
    vertDesc.attributes[VertexAttributePosition].offset = 0;
    vertDesc.attributes[VertexAttributePosition].bufferIndex = MeshVertexBuffer;
    vertDesc.attributes[VertexAttributeColor].format = MTLVertexFormatUChar3;
    vertDesc.attributes[VertexAttributeColor].offset = sizeof(Vertex::position);
    vertDesc.attributes[VertexAttributeColor].bufferIndex = MeshVertexBuffer;
    vertDesc.layouts[MeshVertexBuffer].stride = sizeof(Vertex);
    vertDesc.layouts[MeshVertexBuffer].stepRate = 1;
    vertDesc.layouts[MeshVertexBuffer].stepFunction = MTLVertexStepFunctionPerVertex;

    // Create pipeline state.
    MTLRenderPipelineDescriptor *pipelineDesc = [MTLRenderPipelineDescriptor new];
    pipelineDesc.sampleCount = self.sampleCount;
    pipelineDesc.vertexFunction = vertFunc;
    pipelineDesc.fragmentFunction = fragFunc;
    pipelineDesc.vertexDescriptor = vertDesc;
    pipelineDesc.colorAttachments[0].pixelFormat = self.colorPixelFormat;
    pipelineDesc.depthAttachmentPixelFormat = self.depthStencilPixelFormat;
    pipelineDesc.stencilAttachmentPixelFormat = self.depthStencilPixelFormat;
    _pipelineState = [self.device newRenderPipelineStateWithDescriptor:pipelineDesc error:&error];
    if (!_pipelineState) {
        NSLog(@"Failed to create pipeline state, error %@", error);
        exit(0);
    }
/*
    // Create vertices.triangle
    Vertex verts[] = {
        Vertex{{-0.5, -0.5, 0}, {255, 0, 0, 255}},
        Vertex{{0, 0.5, 0}, {0, 255, 0, 255}},
        Vertex{{0.5, -0.5, 0}, {0, 0, 255, 255}}
    };

x:-0.5 y:0.5,  x:0.5 y:0.5

      x:-0.0 y:0.0,

x:-0.5 y:-0.5,  x:0.5 y:-0.5

// Create vertices.square

*/
    float v=0.95;
    float left = -v;
    float right = v;
    float up = v;
    float down = -v;
    // Create vertices.square
    Vertex verts[] = {
        //xyz  
        Vertex{{left ,down, 0.0}, {0, 0, 255, 255}}, //left down
        Vertex{{left ,up, 0.0}, {255, 0, 0, 255}},  //left up
        Vertex{{right,up, 0.0}, {0, 255, 0, 255}},   //right up 
        Vertex{{left ,down, 0.0}, {0, 255, 0, 255}}, //left down
        Vertex{{right,up, 0.0}, {0, 0, 255, 255}},   //right up 
        Vertex{{right,down, 0.0}, {0, 255, 0, 255}}  //right down
    };
    

    _vertexBuffer = [self.device newBufferWithBytes:verts
                                             length:sizeof(verts)
                                            options:MTLResourceStorageModePrivate];

    // Create uniform buffers.
    for (int i = 0; i < uniformBufferCount; i++) {
        _uniformBuffers[i] = [self.device newBufferWithLength:sizeof(FrameUniforms)
                                          options:MTLResourceCPUCacheModeWriteCombined];
    }
    frame = 0;

    // Create semaphore for each uniform buffer.
    _semaphore = dispatch_semaphore_create(uniformBufferCount);
    uniformBufferIndex = 0;

    // Create command queue
    _commandQueue = [self.device newCommandQueue];

}

- (void)drawRect:(CGRect)rect {
    // Wait for an available uniform buffer.
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);

    // Animation.
    frame++;
    //float rad = frame * 0.01f;
    //float rad = frame * 0.01f;
    //止めちゃう
    float rad = 0.00f;

    float sin = std::sin(rad);
    float cos = std::cos(rad);
    /////////////////////////////////////////////////////
    ///////////https://ja.wikipedia.org/wiki/回転行列
    //////////https://en.wikipedia.org/wiki/Rotation_matrix
    /*
    // X rotation Matrix
    simd::float4x4 rot(simd::float4{1,   0,    0, 0},
                       simd::float4{0, cos, -sin, 0},
                       simd::float4{0, sin,  cos, 0},
                       simd::float4{1,   0,    0, 1});
    */
    // Y rotation Matrix
    simd::float4x4 rot(simd::float4{cos ,  0, sin, 0},
                       simd::float4{0   ,  1,   0, 0},
                       simd::float4{-sin,  0, cos, 0},
                       simd::float4{0   ,  0,   0, 1});

    /*
    // Z rotation Matrix
    simd::float4x4 rot(simd::float4{cos,-sin, 0, 0},
                       simd::float4{sin, cos, 0, 0},
                       simd::float4{0  ,  -0, 1, 0},
                       simd::float4{0  ,   0, 0, 1});
    */
    
    simd::float2 resolution(simd::float2{256, 256});
    float resolutionArr[2];
    resolutionArr[0] = 128;
    resolutionArr[1] = 256;
    // Update the current uniform buffer.
    uniformBufferIndex = (uniformBufferIndex + 1) % uniformBufferCount;
    FrameUniforms *uniforms = (FrameUniforms *)[_uniformBuffers[uniformBufferIndex] contents];
    uniforms->projectionViewModel = rot;
    uniforms->resolution = resolution;
    //uniforms->resolutionArr = resolutionArr;
    
    uniforms->resolutionX = 256.0;
    uniforms->resolutionY = 256.0;

    
    int resolutionXint= 128;
    float resolutionXfloat= 128.0;
    ///////////////////////////////debug sample
    //self.sampleFloat=uniforms->resolutionX;
    //[self debugFloat];
    ///////////////////////////////debug sample
    // Create a command buffer.
    id <MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];

    // Encode render command.
    id <MTLRenderCommandEncoder> encoder =
        [commandBuffer renderCommandEncoderWithDescriptor:self.currentRenderPassDescriptor];
    [encoder setViewport:{0, 0, self.drawableSize.width, self.drawableSize.height, 0, 1}];
    [encoder setDepthStencilState:_depthState];
    [encoder setRenderPipelineState:_pipelineState];
    [encoder setVertexBuffer:_uniformBuffers[uniformBufferIndex]
                      offset:0 atIndex:FrameUniformBuffer];
    [encoder setVertexBuffer:_vertexBuffer offset:0 atIndex:MeshVertexBuffer];
    
    ///////////////////////////////////////////////////////////////////////////////////
    //[encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:3];
    //[encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:4];
    [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
    /////////////////////////////////////////////////////////////////////////////////
    [encoder endEncoding];

    // Set callback for semaphore.
    __block dispatch_semaphore_t semaphore = _semaphore;
    [commandBuffer addCompletedHandler:^(id<MTLCommandBuffer> buffer) {
        dispatch_semaphore_signal(semaphore);
    }];
    [commandBuffer presentDrawable:self.currentDrawable];
    [commandBuffer commit];

    // Draw children.
    [super drawRect:rect];
}
//////////////////////////////////////////////////////////////////////
///////////////////better Objective-C debug method//////////////////////
////////////Objective-Cでメンバ変数をシンプルに宣言する方法////////////////
//////////////https://lab.dolice.net/blog/2013/04/19/objc-property/
///////////////////////////////////////////////////////////////////////
- (void)mainfunc
{
  _sampleStr = @"サンプル";
  _sampleInt = 777;
  _sampleBool = YES;
}

- (void)debugStr
{
  NSLog(@"_sampleStr: %@", _sampleStr);
  NSLog(@"self.sampleStr: %@", self.sampleStr);
  NSLog(@"[self sampleStr]: %@", [self sampleStr]);
}

- (void)debugInt
{
  NSLog(@"_sampleInt: %d", _sampleInt);
  NSLog(@"self.sampleInt: %d", self.sampleInt);
  NSLog(@"[self sampleInt]: %d", [self sampleInt]);
}
- (void)debugFloat
{
  NSLog(@"_sampleFloat: %f", _sampleFloat);
  NSLog(@"self.sampleFloat: %f", self.sampleFloat);
  NSLog(@"[self sampleFloat]: %f", [self sampleFloat]);
}
- (void)debugBool
{
  NSLog(@"_sampleBool: %d", _sampleBool);
  NSLog(@"self.sampleBool: %d", self.sampleBool);
  NSLog(@"[self sampleBool]: %d", [self sampleBool]);
}
@end
