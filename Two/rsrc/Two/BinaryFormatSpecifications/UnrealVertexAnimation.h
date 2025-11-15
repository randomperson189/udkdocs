/*======================================================================

    	Unreal Vertex Animation data structure details
	Copyright 1997-2003 Epic Games, Inc. All Rights Reserved.

========================================================================*/

//
// Note: _WORD is an unsigned 16 bit word.
//       DWORD is an unsigned 32 bit word.
//         INT is a signed 32 bit integer.
//

class FVector
{
public:
	FLOAT X,Y,Z;
};



struct FJSDataHeader
{
	_WORD	NumPolys;
	_WORD	NumVertices;
	_WORD	BogusRot;  		 //(unused)
	_WORD	BogusFrame;		 //(unused)
	DWORD	BogusNormX,BogusNormY,BogusNormZ; //(unused)
	DWORD	FixScale; 		 //(unused)
	DWORD	Unused1,Unused2,Unused3; //(unused)
};

//
// Animation info.
//
struct FJSAnivHeader
{
	_WORD	NumFrames;		// Number of animation frames.
	_WORD	FrameSize;		// Size of one frame of animation.
};

// Texture coordinates associated with a vertex and one or more mesh triangles.
// All triangles sharing a vertex do not necessarily have the same texture
// coordinates at the vertex.
struct FMeshByteUV
{
	BYTE U;
	BYTE V;
};

//
// Mesh triangle.
//
struct FJSMeshTri
{
	_WORD		iVertex[3];		// Vertex indices.
	BYTE		Type;			// James' mesh type. (unused)
	BYTE		Color;			// Color for flat and Gouraud shaded. (unused)
	FMeshByteUV	Tex[3];			// Texture UV coordinates.
	BYTE		TextureNum;		// Source texture offset.
	BYTE		Flags;			// Unreal mesh flags (currently unused).
};

//
// One triangular polygon in a mesh, which references three vertices, and various drawing/texturing information.
//
struct FMeshTri
{
	_WORD		iVertex[3];	// Vertex indices.
	FMeshUV		Tex[3];		// Texture UV coordinates.
	DWORD		PolyFlags;	// Surface flags.
	INT		MaterialIndex;	// Source texture index.
};

//
// Animated vertices: 32 bits per vertex: packed 11,11,10 bit 3d vector.
//
struct FMeshVert
{
	// Variables.
	INT X:11; INT Y:11; INT Z:10;

	// Constructor.
	FMeshVert()
	{}
	FMeshVert( const FVector& In )
	: X((INT)In.X), Y((INT)In.Y), Z((INT)In.Z)
	{}

	// Functions.
	FVector Vector() const
	{
		return FVector( X, Y, Z );
	}
};
