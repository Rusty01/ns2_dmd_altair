// ======= Use however you want, including for profit. Just dont sue anyone over it =======
//
// lua\Intersection.lua
//
//    Created by: Feha
//
// Library for doing some intersection math
//
// ========= For more information, ask me =====================

Intersection = {}


--local references to commonly used functions
local Coords_GetInverse
local Coords_TransformPoint
local Coords_TransformVector

local Vector_DotProduct
local Vector_GetLength

local math_abs

-- local references to own library
local Intersection_LinesegmentOBBIntersection
local Intersection_LinesegmentAABBIntersection
local Intersection_RayOBBIntersection
local Intersection_RayAABBIntersection
local Intersection_RayPlaneIntersection
local Intersection_IsPointInsideOBB
local Intersection_IsPointInsideAABB


function Intersection.LinesegmentOBBIntersection(worldpoint, worldpoint2, OBBcoords, size)
	
	if not worldpoint or not worldpoint2 or not OBBcoords then return end
	size = size or Vector(1,1,1)
	
	local inverseOBB = Coords_GetInverse(OBBcoords)
	local point1 = Coords_TransformPoint( inverseOBB, worldpoint )
	local point2 = Coords_TransformPoint( inverseOBB, worldpoint2 )
	
	local point, fraction = Intersection_LinesegmentAABBIntersection(point1, point2, size)
	
	if point then
		return Coords_TransformPoint( OBBcoords, point ), fraction
	end
	
	return nil, nil
	
end


function Intersection.LinesegmentAABBIntersection(point1, point2, size)
	
	if not point1 or not point2 then return end
	size = size or Vector(1,1,1)
	halfsize = size/2
	local dir = point2-point1
	
	local hitpos = Intersection_RayAABBIntersection( point1, dir, size )
	if hitpos then
		local distance = Vector_GetLength(hitpos-point1)
		local segmentlength = Vector_GetLength(dir)
		if distance < segmentlength then
			return hitpos, 1-(distance/segmentlength)
		end
	end
	
	return nil, nil
	
end


function Intersection.RayOBBIntersection(worldpoint, worlddir, OBBcoords, size)
	
	if not worldpoint or not dir or not OBBcoords then return end
	size = size or Vector(1,1,1)
	
	local point = Coords_TransformPoint( Coords_GetInverse(OBBcoords), worldpoint )
	local dir = Coords_TransformVector( Coords_GetInverse(OBBcoords), worlddir )
	
	local hitpos = Intersection_RayAABBIntersection(point, dir, size)
	
	return Coords_TransformPoint( OBBcoords, hitpos )
	
end


local boxNormals = {
	Vector(1,0,0),
	Vector(0,1,0),
	Vector(0,0,1),
	Vector(-1,0,0),
	Vector(0,-1,0),
	Vector(0,0,-1)
}
function Intersection.RayAABBIntersection(point, dir, size)
	
	if not point or not dir then return end
	size = size or Vector(1,1,1)
	halfsize = size/2
	
	if not Intersection_IsPointInsideAABB(point, size) then
		local radius = {
			size.x / 2,
			size.y / 2,
			size.z / 2
		}
		for i=1,6 do
			
			local normal = boxNormals[i]
			if Vector_DotProduct(normal, dir) < 0 then
				local planePos = normal * radius[((i-1)%3)+1]
				local hitpos = Intersection_RayPlaneIntersection( point, dir, planePos, normal )
				
				if hitpos
					-- and Intersection_IsPointInsideAABB(hitpos, size) then -- has rounding errors after 7 decimals
					and (hitpos.x <= halfsize.x and hitpos.x >= -halfsize.x or i == 1 or i == 4) -- is in box (ignore current face-normal)
					and (hitpos.y <= halfsize.y and hitpos.y >= -halfsize.y or i == 2 or i == 5)
					and (hitpos.z <= halfsize.z and hitpos.z >= -halfsize.z or i == 3 or i == 6) then
					-- and Intersection.IsPointInsideAAFace(hitpos, radius[((i)%3)+1], radius[((i+1)%3)+1], planePos) then
					
					return hitpos
				end
				
			end
			
		end
		
	else
		return point
	end
	
	return nil
	
end


function Intersection.RayPlaneIntersection( Start, Dir, Pos, Normal )
	
	local A = Vector_DotProduct(Normal, Dir)
	
	--Check if the ray is aiming towards the plane
	if A < 0 then
		
		local B = Vector_DotProduct(Normal, (Pos-Start))
		
		--Check if the ray origin in front of plane
		if B < 0 then
			return (Start + Dir * (B/A))
		end
		
	--Check if the ray is parallel to the plane
	elseif A == 0 then
		
		--Check if the ray origin inside the plane
		if Vector_DotProduct(Normal, (Pos-Start)) == 0 then
			return Start
		end
		
	end
	
	return nil
	
end


function Intersection.IsPointInsideOBB(worldpoint, OBBcoords, size)

	if not worldpoint or not OBBcoords then return end
	
	local point = Coords_TransformPoint( Coords_GetInverse(OBBcoords), worldpoint )
	
	return Intersection_IsPointInsideAABB(point, size)
	
end

function Intersection.IsPointInsideAABB(point, size)

	if not point then return false end
	size = size or Vector(1,1,1)
	
	local maxcorner = size/2
	local mincorner = -maxcorner
	-- Returns true if the point is inside the AABB. Uses math.abs to allow inverted axes
	local inside = -math_abs(mincorner.x) <= point.x and point.x <= math_abs(maxcorner.x)
				and -math_abs(mincorner.y) <= point.y and point.y <= math_abs(maxcorner.y)
				and -math_abs(mincorner.z) <= point.z and point.z <= math_abs(maxcorner.z)
	
	return inside
end


--local references to commonly used functions
Coords_GetInverse			= Coords.GetInverse
Coords_TransformPoint		= Coords.TransformPoint
Coords_TransformVector		= Coords.TransformVector

Vector_DotProduct			= Vector.DotProduct
Vector_GetLength			= Vector.GetLength

math_abs					= math.abs

-- local references to own library
Intersection_LinesegmentOBBIntersection		= Intersection.LinesegmentOBBIntersection
Intersection_LinesegmentAABBIntersection	= Intersection.LinesegmentAABBIntersection
Intersection_RayOBBIntersection				= Intersection.RayOBBIntersection
Intersection_RayAABBIntersection			= Intersection.RayAABBIntersection
Intersection_RayPlaneIntersection			= Intersection.RayPlaneIntersection
Intersection_IsPointInsideOBB				= Intersection.IsPointInsideOBB
Intersection_IsPointInsideAABB				= Intersection.IsPointInsideAABB
