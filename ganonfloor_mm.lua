addr_colCtx = 0x3E7350 -- U
addr_exitList = 0x3FF380 -- U

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

lookup_entry_count = mainmemory.read_s32_be(addr_colCtx+0x1C)*mainmemory.read_s32_be(addr_colCtx+0x20)*mainmemory.read_s32_be(addr_colCtx+0x24)

already_dumped_node_indexes = {}

dyna_polyListMax = mainmemory.read_u32_be(addr_colCtx + 0x50 + 0x1410)
dyna_vtxListMax = mainmemory.read_u32_be(addr_colCtx + 0x50 + 0x1414)

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

for i=0,lookup_entry_count-1 do
	for j=0,1 do -- include floors and walls, but not ceilings
		
		nodeIndex = mainmemory.read_u16_be(colCtx_lookupTbl - 0x80000000 + 6*i + 2*j)
		
		while nodeIndex ~= 0xFFFF and not already_dumped_node_indexes[nodeIndex] do
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
				
				print(string.format("exit %04X - nodeIndex %04X polyId %04X surfaceType %04X - (%d,%d,%d), (%d,%d,%d), (%d,%d,%d)", exitValue, nodeIndex, polyId, polySurfaceTypeId, vertAX,vertAY,vertAZ, vertBX,vertBY,vertBZ, vertCX,vertCY,vertCZ))
			end
			
			already_dumped_node_indexes[nodeIndex] = true
			
			nodeIndex = mainmemory.read_u16_be(colCtx_polyNodes_tbl - 0x80000000 + 4*nodeIndex + 2)
		end
	end
end