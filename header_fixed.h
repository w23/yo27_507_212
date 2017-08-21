/* File generated with Shader Minifier 1.1.4
 * http://www.ctrl-alt-test.fr
 */
#ifndef HEADER_H_
# define HEADER_H_

const char *header_glsl =
"#version 130\n"
"#define Z(s)textureSize(S[s],0)\n"
"#define T(s,c)texture2D(S[s],(c)/Z(s))\n"
"#define P(s,c)texture2D(S[s],(c))\n"
"#define X gl_FragCoord.xy\n"
"uniform sampler2D S[7];"
"uniform int F;"
"float t=float(F)/352800.;"
"const vec3 E=vec3(.0,.001,1.);"
"const float PI=3.141593;"//, PI2 = PI * 2.;
;
 

#endif // HEADER_H_
