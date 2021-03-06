/*
 * CC3PODVertexSkinning.m
 *
 * cocos3d 2.0.0
 * Author: Chris Myers, Bill Hollings
 * Copyright (c) 2011 Chris Myers. All rights reserved.
 * Copyright (c) 2010-2013 The Brenwill Workshop Ltd. All rights reserved.
 * http://www.brenwill.com
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * http://en.wikipedia.org/wiki/MIT_License
 * 
 * See header file CC3PODVertexSkinning.h for full API documentation.
 */

#import "CC3PODVertexSkinning.h"
#import "CC3PODMesh.h"
#import "CC3VertexSkinning.h"
#import "CC3PVRTModelPOD.h"
#import "CC3PODNode.h"


#pragma mark -
#pragma mark CC3PODSkinMeshNode

@implementation CC3PODSkinMeshNode

-(int) podIndex { return podIndex; }

-(void) setPodIndex: (int) aPODIndex { podIndex = aPODIndex; }

-(int) podContentIndex { return podContentIndex; }

-(void) setPodContentIndex: (int) aPODIndex { podContentIndex = aPODIndex; }

-(int) podParentIndex { return podParentIndex; }

-(void) setPodParentIndex: (int) aPODIndex { podParentIndex = aPODIndex; }

-(int) podMaterialIndex { return podMaterialIndex; }

-(void) setPodMaterialIndex: (int) aPODIndex { podMaterialIndex = aPODIndex; }

/** Overridden to extract the bone batches from the associated POD mesh structure */
-(id) initAtIndex: (int) aPODIndex fromPODResource: (CC3PODResource*) aPODRez {
	if ( (self = [super initAtIndex: aPODIndex fromPODResource: aPODRez]) ) {
		if (self.podContentIndex >= 0) {
			SPODMesh* psm = (SPODMesh*)[aPODRez meshPODStructAtIndex: self.podContentIndex];
			int batchCount = psm->sBoneBatches.nBatchCnt;
			for (int batchIndex = 0; batchIndex < batchCount; batchIndex++) {
				[skinSections addObject: [CC3PODSkinSection skinSectionFromBatchAtIndex: batchIndex
																		   fromSPODMesh: psm
																				forNode: self]];
			}
		}
	}
	return self; 
}

// Template method that populates this instance from the specified other instance.
// This method is invoked automatically during object copying via the copyWithZone: method.
-(void) populateFrom: (CC3PODSkinMeshNode*) another {
	[super populateFrom: another];
	
	podIndex = another.podIndex;
	podContentIndex = another.podContentIndex;
	podParentIndex = another.podParentIndex;
	podMaterialIndex = another.podMaterialIndex;
}

/** Link the nodes in the bone batches. */
-(void) linkToPODNodes: (CCArray*) nodeArray {
	[super linkToPODNodes: nodeArray];
	for (CC3PODSkinSection* skinSctn in skinSections) [skinSctn linkToPODNodes: nodeArray];
}

-(NSString*) description {
	return [NSString stringWithFormat: @"%@ (POD index: %i)", [super description], podIndex];
}

@end

	
#pragma mark -
#pragma mark CC3PODSkinSection

@implementation CC3PODSkinSection

-(id) init {
	if ( (self = [super init]) ) {
		_podBoneCount = 0;
		_podBoneNodeIndices = NULL;
	}
	return self;
}

-(id) initFromBatchAtIndex: (int) aBatchIndex
			  fromSPODMesh: (PODStructPtr) aSPODMesh
				   forNode: (CC3SkinMeshNode*) aNode {
	SPODMesh* psm = (SPODMesh*)aSPODMesh;
	if ( (self = [self initForNode: aNode]) ) {
		CPVRTBoneBatches* pBatches = &psm->sBoneBatches;
		int batchCount = pBatches->nBatchCnt;
			
		int currFaceOffset = pBatches->pnBatchOffset[aBatchIndex];
		int nextFaceOffset = (aBatchIndex < batchCount - 1)
									? pBatches->pnBatchOffset[aBatchIndex + 1]
									: psm->nNumFaces;
			
		vertexStart = [aNode.mesh vertexIndexCountFromFaceCount: currFaceOffset];
		vertexCount =  [aNode.mesh vertexIndexCountFromFaceCount: (nextFaceOffset - currFaceOffset)];
			
		_podBoneCount = pBatches->pnBatchBoneCnt[aBatchIndex];
		_podBoneNodeIndices = &(pBatches->pnBatches[aBatchIndex * pBatches->nBatchBoneMax]);
	}
	return self;
}

+(id) skinSectionFromBatchAtIndex: (int) aBatchIndex
					 fromSPODMesh: (PODStructPtr) aSPODMesh
						  forNode: (CC3SkinMeshNode*) aNode {
	return [[[self alloc] initFromBatchAtIndex: aBatchIndex fromSPODMesh: aSPODMesh forNode: aNode] autorelease];

}

-(void) linkToPODNodes: (CCArray*) nodeArray {
	for (int boneNum = 0; boneNum < _podBoneCount; boneNum++) {
		int boneIndex = _podBoneNodeIndices[boneNum];
		CC3Bone* boneNode = [nodeArray objectAtIndex: boneIndex];
		LogTrace(@"Adding bone node %@ at index %i to %@", boneNode, boneIndex, self);
		[self addBone: boneNode];
	}
	_podBoneNodeIndices = NULL;		// Remove reference since this array will be released
	_podBoneCount = 0;
}

-(NSString*) fullDescription {
	return [NSString stringWithFormat: @"%@ from original bone count %i of indices at %p",
			[super fullDescription], _podBoneCount, _podBoneNodeIndices];
}

@end


#pragma mark -
#pragma mark CC3PODBone

@implementation CC3PODBone

-(int) podIndex { return podIndex; }

-(void) setPodIndex: (int) aPODIndex { podIndex = aPODIndex; }

-(int) podContentIndex { return podContentIndex; }

-(void) setPodContentIndex: (int) aPODIndex { podContentIndex = aPODIndex; }

-(int) podParentIndex { return podParentIndex; }

-(void) setPodParentIndex: (int) aPODIndex { podParentIndex = aPODIndex; }

// Template method that populates this instance from the specified other instance.
// This method is invoked automatically during object copying via the copyWithZone: method.
-(void) populateFrom: (CC3PODNode*) another {
	[super populateFrom: another];
	
	podIndex = another.podIndex;
	podContentIndex = another.podContentIndex;
	podParentIndex = another.podParentIndex;
}

-(NSString*) description {
	return [NSString stringWithFormat: @"%@ (POD index: %i)", [super description], podIndex];
}

@end

