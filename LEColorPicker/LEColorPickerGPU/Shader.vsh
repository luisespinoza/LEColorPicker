//
//  Shader.vsh
//  LearningOpenGLES
//
//  Created by Luis Enrique Espinoza Severino on 07-03-13.
//  Copyright (c) 2013 LuisEspinoza. All rights reserved.
//

#define FLT_MAX 3.402823466e38

attribute vec3 position;

uniform 	 codebook[codebook_h][codebook_w]
void main()
{
    int i,j;
    float2 imin;
    float nd, dd;
    float3 dv;
    
    nd = FLT_MAX;
    for( j=0; j<codebook_h; j++ )
        for( i=0; i<codebook_w; i++ )
        {
            dv = ac-codebook[j][i];
            dd = dot(dv,dv);
            if( nd>dd )
            {
                nd=dd;
                imin=float2( i, j );
            }
        }
    imin = 2*(imin+.5)/float2(codebook_w,codebook_h)-1;
    
    hPosition = float4( imin, 0,1);
    bc=ac;
}
