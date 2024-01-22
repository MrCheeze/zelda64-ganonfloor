addr_colCtx = 0x1C9520 -- NTSC 1.2
addr_exitList = 0x1DAB64 -- NTSC 1.2

exitList = mainmemory.read_u32_be(addr_exitList)

colCtx_colHeader = mainmemory.read_u32_be(addr_colCtx)
colCtx_lookupTbl = mainmemory.read_u32_be(addr_colCtx+0x40)
colCtx_polyNodes_tbl = mainmemory.read_u32_be(addr_colCtx+0x48)
colCtx_polyNodes_polyCheckTbl = mainmemory.read_u32_be(addr_colCtx+0x4C)
colCtx_dyna_polyList = mainmemory.read_u32_be(addr_colCtx+0x50+0x13F0)
colCtx_dyna_vtxList = mainmemory.read_u32_be(addr_colCtx+0x50+0x13F4)

colCtx_colHeader_vtxList = mainmemory.read_u32_be(colCtx_colHeader - 0x80000000 + 0x10)
colCtx_colHeader_polyList = mainmemory.read_u32_be(colCtx_colHeader - 0x80000000 + 0x18)
colCtx_colHeader_surfaceTypeList = mainmemory.read_u32_be(colCtx_colHeader - 0x80000000 + 0x1C)

colCtx_minBoundsX = mainmemory.readfloat(addr_colCtx+0x4, true)
colCtx_minBoundsY = mainmemory.readfloat(addr_colCtx+0x8, true)
colCtx_minBoundsZ = mainmemory.readfloat(addr_colCtx+0xC, true)
colCtx_subdivAmountX = mainmemory.read_s32_be(addr_colCtx+0x1C)
colCtx_subdivAmountY = mainmemory.read_s32_be(addr_colCtx+0x20)
colCtx_subdivAmountZ = mainmemory.read_s32_be(addr_colCtx+0x24)
colCtx_subdivLengthX = mainmemory.readfloat(addr_colCtx+0x28, true)
colCtx_subdivLengthY = mainmemory.readfloat(addr_colCtx+0x2C, true)
colCtx_subdivLengthZ = mainmemory.readfloat(addr_colCtx+0x30, true)

dyna_polyListMax = mainmemory.read_u32_be(addr_colCtx + 0x50 + 0x1408)
dyna_vtxListMax = mainmemory.read_u32_be(addr_colCtx + 0x50 + 0x140C)

dyna_polyCount = 0
dyna_vtxCount = 0

for i=0,49 do
	if (mainmemory.read_u16_be(addr_colCtx + 0x50 + 0x138C + 2*i) & 0x0001) ~= 0 then
		-- bgActor #i is in use
		bgActor_colHeader = mainmemory.read_u32_be(addr_colCtx + 0x50 + 0x4 + 0x64*i + 4)
		
		bgActor_vtxCount = mainmemory.read_u16_be(bgActor_colHeader - 0x80000000 + 0xC)
		dyna_vtxCount = dyna_vtxCount + bgActor_vtxCount

		bgActor_polyCount = mainmemory.read_u16_be(bgActor_colHeader - 0x80000000 + 0x14)
		dyna_polyCount = dyna_polyCount + bgActor_polyCount
	end
end

print(string.format("%08X colCtx_dyna_vtxList (used=%d/%d)", colCtx_dyna_vtxList, dyna_vtxCount, dyna_vtxListMax))
if dyna_vtxCount>dyna_vtxListMax then
	vtx_overflow_start = colCtx_dyna_vtxList + 6*dyna_vtxListMax
	vtx_overflow_end = colCtx_dyna_vtxList + 6*dyna_vtxCount
	print(string.format("!!! dyna vtxList overflow into %08X-%08X !!!", vtx_overflow_start, vtx_overflow_end))
end
print(string.format("%08X colCtx_dyna_polyList (used=%d/%d)", colCtx_dyna_polyList, dyna_polyCount, dyna_polyListMax))
if dyna_polyCount>dyna_polyListMax then
	poly_overflow_start = colCtx_dyna_polyList + 0x10*dyna_polyListMax
	poly_overflow_end = colCtx_dyna_polyList + 0x10*dyna_polyCount
	print(string.format("!!! dyna polyList overflow into %08X-%08X !!!", poly_overflow_start, poly_overflow_end))
end
print(string.format("%08X colCtx_polyNodes_polyCheckTbl", colCtx_polyNodes_polyCheckTbl))
print(string.format("%08X colCtx_polyNodes_tbl", colCtx_polyNodes_tbl))
print(string.format("%08X colCtx_lookupTbl", colCtx_lookupTbl))
print(string.format("%08X exitList", exitList))
print(string.format("%08X colCtx_colHeader_surfaceTypeList", colCtx_colHeader_surfaceTypeList))
print(string.format("%08X colCtx_colHeader_polyList", colCtx_colHeader_polyList))
print(string.format("%08X colCtx_colHeader_vtxList", colCtx_colHeader_vtxList))
print(string.format("%08X colCtx_colHeader", colCtx_colHeader))

s=""
i = 0
for zi=0,colCtx_subdivAmountZ-1 do
	for yi=0,colCtx_subdivAmountY-1 do
		for xi=0,colCtx_subdivAmountX-1 do
			
			sector_min_x = colCtx_minBoundsX + colCtx_subdivLengthX*xi - 50
			sector_min_y = colCtx_minBoundsY + colCtx_subdivLengthY*yi - 50
			sector_min_z = colCtx_minBoundsZ + colCtx_subdivLengthZ*zi - 50
			sector_max_x = colCtx_minBoundsX + colCtx_subdivLengthX*(xi+1) + 50
			sector_max_y = colCtx_minBoundsY + colCtx_subdivLengthY*(yi+1) + 50
			sector_max_z = colCtx_minBoundsZ + colCtx_subdivLengthZ*(zi+1) + 50

			for j=0,1 do -- include floors and walls, but not ceilings
				
				nodeIndex = mainmemory.read_u16_be(colCtx_lookupTbl - 0x80000000 + 6*i + 2*j)
				
				while nodeIndex ~= 0xFFFF do
					polyId = mainmemory.read_u16_be(colCtx_polyNodes_tbl - 0x80000000 + 4*nodeIndex)
					polySurfaceTypeId = mainmemory.read_u16_be(colCtx_colHeader_polyList - 0x80000000 + 0x10*polyId)
					surfaceExitIndex = mainmemory.readbyte(colCtx_colHeader_surfaceTypeList - 0x80000000 + 8*polySurfaceTypeId + 2) & 0x1F
					
					if (surfaceExitIndex ~= 0) then
					
						exitValue = mainmemory.read_u16_be(exitList - 0x80000000 + 2*(surfaceExitIndex-1))
					
						polyVertIdA = mainmemory.read_u16_be(colCtx_colHeader_polyList - 0x80000000 + 0x10*polyId + 2) & 0x1FFF
						polyVertIdB = mainmemory.read_u16_be(colCtx_colHeader_polyList - 0x80000000 + 0x10*polyId + 4) & 0x1FFF
						polyVertIdC = mainmemory.read_u16_be(colCtx_colHeader_polyList - 0x80000000 + 0x10*polyId + 6)
						
						vertAX = mainmemory.read_s16_be(colCtx_colHeader_vtxList - 0x80000000 + 6*polyVertIdA + 0)
						vertAY = mainmemory.read_s16_be(colCtx_colHeader_vtxList - 0x80000000 + 6*polyVertIdA + 2)
						vertAZ = mainmemory.read_s16_be(colCtx_colHeader_vtxList - 0x80000000 + 6*polyVertIdA + 4)
						vertBX = mainmemory.read_s16_be(colCtx_colHeader_vtxList - 0x80000000 + 6*polyVertIdB + 0)
						vertBY = mainmemory.read_s16_be(colCtx_colHeader_vtxList - 0x80000000 + 6*polyVertIdB + 2)
						vertBZ = mainmemory.read_s16_be(colCtx_colHeader_vtxList - 0x80000000 + 6*polyVertIdB + 4)
						vertCX = mainmemory.read_s16_be(colCtx_colHeader_vtxList - 0x80000000 + 6*polyVertIdC + 0)
						vertCY = mainmemory.read_s16_be(colCtx_colHeader_vtxList - 0x80000000 + 6*polyVertIdC + 2)
						vertCZ = mainmemory.read_s16_be(colCtx_colHeader_vtxList - 0x80000000 + 6*polyVertIdC + 4)
						
						tri_min_x = math.min(vertAX,vertBX,vertCX)
						tri_min_y = math.min(vertAY,vertBY,vertCY)
						tri_min_z = math.min(vertAZ,vertBZ,vertCZ)
						tri_max_x = math.max(vertAX,vertBX,vertCX)
						tri_max_y = math.max(vertAY,vertBY,vertCY)
						tri_max_z = math.max(vertAZ,vertBZ,vertCZ)
						
						if tri_max_x >= sector_min_x and tri_min_x <= sector_max_x and tri_max_y >= sector_min_y and tri_min_y <= sector_max_y and tri_max_z >= sector_min_z and tri_min_z <= sector_max_z then
							s=s..string.format("exit %04X - nodeIndex %04X polyId %04X surfaceType %04X - poly (%d,%d,%d), (%d,%d,%d), (%d,%d,%d) - sector [%s,%s],[%s,%s],[%s,%s]\n", exitValue, nodeIndex, polyId, polySurfaceTypeId, vertAX,vertAY,vertAZ, vertBX,vertBY,vertBZ, vertCX,vertCY,vertCZ, sector_min_x,sector_max_x, sector_min_y,sector_max_y, sector_min_z,sector_max_z)
						end
					end
					
					nodeIndex = mainmemory.read_u16_be(colCtx_polyNodes_tbl - 0x80000000 + 4*nodeIndex + 2)
				end
			end
			i = i + 1
		end
	end
end
print(s)
