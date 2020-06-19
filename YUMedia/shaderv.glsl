attribute vec4 position;
attribute vec2 positionColor;
uniform mat4 projectionMatrix;
uniform mat4 modelViewMatrix;

varying lowp vec2 varyTextCoord;

void main()
{
    varyTextCoord = positionColor;
    
    vec4 vPos;
    vPos = projectionMatrix * modelViewMatrix * position;
    gl_Position = vPos;
}
