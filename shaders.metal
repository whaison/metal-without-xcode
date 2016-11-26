#include <simd/simd.h>
#include "common.h"

using namespace metal;

struct VertexInput {
    float3 position [[attribute(VertexAttributePosition)]];
    half4 color [[attribute(VertexAttributeColor)]];

};

struct ShaderInOut {
    float4 position [[position]];
    half4  color;
    float2 resolution;
};


//引数に上で定義してるVertexInput型の in として [[stage_in]]
//// 頂点シェーダからの出力は[[stage_in]]で受け取る
//定数constant として
//"common.h"に定義されてる 
//FrameUniforms型 =float4x4 projectionViewModel 
//の4x4のMVP(Model,View,Projection)のMatrixが
//グローバル変数としてuniformsとして 
//"common.h"に定義されてる 
//enum のBufferIndex ２番目のFrameUniformBuffer=1
//[[buffer(FrameUniformBuffer)]]
//

vertex ShaderInOut vert(VertexInput in [[stage_in]],
	   constant FrameUniforms& uniforms [[buffer(FrameUniformBuffer)]]) {
    ShaderInOut out;
    // 頂点シェーダからの出力はinとして [[stage_in]]で受け取る
    float4 pos4 = float4(in.position, 1.0);
    //float4 pos4 = float4(1.0,1.0,1.0, 1.0);
    out.position = uniforms.projectionViewModel * pos4;
    out.color = in.color / 255.0;
    out.resolution = float2(uniforms.resolutionX,uniforms.resolutionY);
    //out.color = in.color;
    return out;
}
fragment half4 frag(ShaderInOut in [[stage_in]]) {
    //return in.color;
    //[Metal] iOS Metalのちょっとしたメモ //edo_m18先生
    //http://qiita.com/edo_m18/items/5e03f7fa317b922b5a42
    //gl_FragCoord相当の処理
    float2 vertexpos =float2(in.position.x,in.position.y);
    float2 resolution=float2(in.resolution.x,in.resolution.y);
    float2 position = vertexpos.xy / resolution.xy;////GLSL001

    float Left0_Right1_x=(position.x*0.5);
    float Down0_Up1_y=1-(position.y*0.5);//*-1,じゃなく1-value

    half4 RGBA= half4(Left0_Right1_x, Down0_Up1_y, 1.0, 1.0);
    //half4 RGBA= half4(0.1,0.5, 0.5, 1.0);
    return RGBA;
}
