extends SceneTree
## Explicit, deterministic bake of Map 2 ONLY. Map 1 and local overrides are untouched.
const L = preload("res://scripts/world/valley_layout.gd")
const ART := "res://assets/world/valley/"
const ENV := "res://assets/menu/environment/"
const FOREST := "res://assets/world/forest/"
const BUSH := "res://assets/sprites/objects/bush_small_compact_leafy_for/rotations/bush_small_compact_leafy_for.png"
const LOG := "res://assets/sprites/objects/fallen_log_mossy_fallen_oak/rotations/fallen_log_mossy_fallen_oak.png"
var world: Node2D
var rng := RandomNumberGenerator.new()
var paths: Dictionary
var water_parts: Array[PackedVector2Array] = []
var outlines: Array[PackedVector2Array] = []
var solids: Array[PackedVector2Array] = []
var textures: Dictionary = {}
var groups: Dictionary = {}
var serial := 0
var tree_positions: Array[Vector2] = []
var tiles: TileSet
var depth_texture: Texture2D

func _initialize() -> void: call_deferred("build")
func build() -> void:
	rng.seed=L.SEED
	paths=L.routes()
	world=Node2D.new()
	world.name="ValeDasNascentes"
	world.y_sort_enabled=true
	world.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	world.set_script(load("res://scripts/world/valley_region.gd"))
	for entry in [["GroundDetails",-18],["Paths",-15],["Elevations",-14],["Banks",-13],["Water",-12],["WaterDecorations",-9],["Bridges",-6],["Waterfalls",-7],["LowVegetation",-3],["TreesBack",0],["TreesFront",0],["Decorations",0],["Obstacles",0],["SpawnPoints",0],["SlimeSpawnPoints",0],["Transitions",0],["PointsOfInterest",0]]:
		var group:=Node2D.new()
		group.name=entry[0]
		group.z_index=entry[1]
		group.y_sort_enabled=entry[1]==0
		add(world,group)
		groups[entry[0]]=group
	ground()
	water_geometry()
	elevations()
	paths_and_bridges()
	plant()
	aquatic_life()
	points()
	var player:Node2D=load("res://scenes/player.tscn").instantiate()
	player.name="Player"
	player.position=L.SPAWN
	player.world_bounds=Rect2(24,44,3152,3132)
	add(world,player)
	var packed:=PackedScene.new()
	var result:=packed.pack(world)
	if result==OK: result=ResourceSaver.save(packed,"res://scenes/regions/ValeDasNascentes.tscn")
	print("VALLEY_BUILD result=",result," trees=",tree_positions.size()," water_shapes=",water_parts.size()," objects=",serial)
	world.free()
	await process_frame
	quit(result)

func add(parent:Node,child:Node) -> void:
	parent.add_child(child)
	child.owner=world
func poly(parent:Node,pts:PackedVector2Array,color:Color,label:String="Surface") -> Polygon2D:
	var p:=Polygon2D.new()
	p.name=label
	p.polygon=pts
	p.color=color
	add(parent,p)
	return p
func box(rect:Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position,rect.position+Vector2(rect.size.x,0),rect.end,rect.position+Vector2(0,rect.size.y)])
func block(parent:Node,pts:PackedVector2Array) -> void:
	var body:=StaticBody2D.new()
	body.name="SolidBase"
	body.collision_layer=2
	body.collision_mask=1
	add(parent,body)
	var shape:=CollisionPolygon2D.new()
	shape.polygon=pts
	add(body,shape)
	solids.append(pts)
func tex(path:String) -> Texture2D:
	if not textures.has(path): textures[path]=load(path)
	return textures[path]
func prop(group:Node,path:String,at:Vector2,scale_:float=1.0,solid:bool=false,label:String="Prop") -> Node2D:
	serial+=1
	var obj:=Node2D.new()
	obj.name=label+"_%04d"%serial
	obj.position=at.round()
	add(group,obj)
	var texture:=tex(path)
	var used:=texture.get_image().get_used_rect()
	var shadow:=poly(obj,L.blob(Vector2(0,-2),Vector2(maxf(used.size.x*scale_*.24,8),5),0,16),Color(0.06,.15,.12,.25),"ContactShadow")
	shadow.z_index=-1
	var sprite:=Sprite2D.new()
	sprite.name="Sprite"
	sprite.texture=texture
	sprite.centered=false
	sprite.position=-Vector2(used.position.x+used.size.x*.5,used.end.y-2)*scale_
	sprite.scale=Vector2.ONE*scale_
	add(obj,sprite)
	if solid:
		# Physics uses the same foot anchor as the sprite, never its transparent canvas.
		var rect:=Rect2(-18,-20,36,20)
		var body:=StaticBody2D.new()
		body.name="SolidBase"
		body.collision_layer=2
		body.collision_mask=1
		add(obj,body)
		var shape:=CollisionPolygon2D.new()
		shape.polygon=box(rect)
		add(body,shape)
	return obj

func ground() -> void:
	tiles=load("res://assets/world/clearing_tileset.tres")
	var g:=TileMapLayer.new()
	g.name="Ground"
	g.tile_set=tiles
	g.z_index=-20
	g.modulate=Color(.82,1.06,.94)
	add(world,g)
	for y in 100:
		for x in 100:
			g.set_cell(Vector2i(x,y),0,Vector2i.ZERO,TileSetAtlasSource.TRANSFORM_FLIP_H if (x+y)%2==0 else 0)
	for i in 85:
		var at:=Vector2(rng.randf_range(0,3200),rng.randf_range(0,3200))
		var p:=poly(groups.GroundDetails,L.blob(at,Vector2(rng.randf_range(80,240),rng.randf_range(60,180)),i),Color("688b57"))
		p.modulate.a=.26

func water_geometry() -> void:
	for b in L.basins(): water_parts.append(L.blob(b[0],b[1],water_parts.size()))
	for s in L.streams(): water_parts.append(L.ribbon(s[0],s[1]))
	for at in [Vector2(640,420),Vector2(2470,410),Vector2(1600,1010)]: water_parts.append(L.blob(at,Vector2(72,46),at.x))
	# A connected wetland at the southwest, shallow and traversable between deep pools.
	for i in 7:
		var at:=Vector2(450+(i%3)*150,2420+(i/3)*160)
		poly(groups.Banks,L.blob(at,Vector2(160,90),i),Color("579b88"),"MarshShallows")
		if i%2==0: water_parts.append(L.blob(at+Vector2(15,0),Vector2(78,50),i))
	# Union only for rendering the banks: no internal shorelines at river junctions.
	for part in water_parts:
		var merged:=part
		var again:=true
		while again:
			again=false
			for i in outlines.size():
				var union:=Geometry2D.merge_polygons(merged,outlines[i])
				if union.size()==1:
					merged=union[0]
					outlines.remove_at(i)
					again=true
					break
		outlines.append(merged)
	var material:=ShaderMaterial.new()
	material.shader=load("res://scripts/world/valley_water.gdshader")
	depth_texture=make_depth_texture()
	material.set_shader_parameter("depth_map",depth_texture)
	var bed:=Node2D.new()
	bed.name="WaterBed"
	bed.z_index=-13
	add(world,bed)
	var bed_material:=ShaderMaterial.new()
	bed_material.shader=load("res://scripts/world/valley_bed.gdshader")
	bed_material.set_shader_parameter("depth_map",depth_texture)
	groups.Water.z_index=-11
	for outline in outlines:
		for band in []:
			for expanded in Geometry2D.offset_polygon(outline,band[0],Geometry2D.JOIN_ROUND):
				poly(groups.Banks,expanded,band[1],"WetBank")
		poly(bed,outline,Color.WHITE,"MineralBed").material=bed_material
		poly(groups.Water,outline,Color.WHITE,"ConnectedWater").material=material
	water_bank_tiles()
	# Clip each component independently: bridge apertures stay real holes in physics,
	# even where multiple streams join one large connected water polygon.
	for part in water_parts:
		var fragments:Array[PackedVector2Array]=[part]
		for bridge:Rect2 in L.BRIDGES:
			var clipped:Array[PackedVector2Array]=[]
			for fragment in fragments:
				clipped.append_array(Geometry2D.clip_polygons(fragment,box(bridge)))
			fragments=clipped
		for fragment in fragments:
			if fragment.size()>2: block(groups.Obstacles,fragment)
	# Islets are scenic rocks within deep water (not reachable spawn locations).
	for pair in [[Vector2(1490,1760),Vector2(90,55)],[Vector2(2480,2650),Vector2(78,55)],[Vector2(2630,880),Vector2(58,40)]]:
		poly(groups.WaterDecorations,L.blob(pair[0],pair[1]+Vector2(14,10)),Color("70c7bd"),"IslandShallow")
		poly(groups.WaterDecorations,L.blob(pair[0],pair[1]),Color("aeb981"),"IslandSand")
		poly(groups.WaterDecorations,L.blob(pair[0],pair[1]-Vector2(15,12)),Color("6d994e"),"IslandGrass")
		prop(groups.Decorations,ENV+"stone.png",pair[0]+Vector2(0,15),2)
		prop(groups.Decorations,FOREST+"fern.png",pair[0]+Vector2(10,-10))
		prop(groups.Decorations,ENV+"flowers.png",pair[0]+Vector2(-30,20))

func paths_and_bridges() -> void:
	for key in paths:
		var c:Curve2D=paths[key]
		var p:=poly(groups.Paths,L.ribbon(c,29),Color("9da76b"),key)
		var material:=ShaderMaterial.new()
		material.shader=load("res://scripts/world/forest_surface.gdshader")
		material.set_shader_parameter("terrain_atlas",load("res://assets/tilesets/grass_dirt_v3_32x32.png"))
		material.set_shader_parameter("atlas_origin",Vector2(224,32))
		material.set_shader_parameter("texture_strength",.28)
		p.material=material
	for i in L.BRIDGES.size():
		var rect:Rect2=L.BRIDGES[i]
		var parent:=Node2D.new()
		parent.name="Bridge%d"%(i+1)
		add(groups.Bridges,parent)
		poly(parent,box(Rect2(rect.position+Vector2(0,6),rect.size)),Color("293f3c"),"Shadow")
		poly(parent,box(rect),Color("4b3732"),"Frame")
		var vertical:=rect.size.y>rect.size.x
		var length:=rect.size.y if vertical else rect.size.x
		for step in range(3,int(length)-3,14):
			var plank:=Rect2(rect.position+Vector2(4,step),Vector2(rect.size.x-8,12)) if vertical else Rect2(rect.position+Vector2(step,4),Vector2(12,rect.size.y-8))
			poly(parent,box(plank),Color("b28350") if step%3==0 else Color("a57546"),"Plank")
			var shine:=Rect2(plank.position,Vector2(plank.size.x,2))
			poly(parent,box(shine),Color("d0a064"))
		for side in [0,1]:
			var rail:=Rect2(rect.position+Vector2(side*(rect.size.x-5),0),Vector2(5,rect.size.y)) if vertical else Rect2(rect.position+Vector2(0,side*(rect.size.y-5)),Vector2(rect.size.x,5))
			poly(parent,box(rail),Color("624632"),"Rail")
			block(parent,box(rail))
			for t in [0.0,.33,.66,1.0]:
				var at:Vector2=rail.position+rail.size*t
				poly(parent,box(Rect2(at-Vector2(4,9),Vector2(10,14))),Color("805838"),"Post")

func near_water(at:Vector2,margin:float=0) -> bool:
	for shape in outlines:
		if Geometry2D.is_point_in_polygon(at,shape): return true
		if margin>0:
			for i in range(0,shape.size(),2):
				if at.distance_to(Geometry2D.get_closest_point_to_segment(at,shape[i],shape[(i+2)%shape.size()]))<margin: return true
	return false
func near_bridge(at:Vector2,margin:float=0) -> bool:
	for r:Rect2 in L.BRIDGES:
		if r.grow(margin).has_point(at): return true
	return false
func reserved(at:Vector2,margin:float=0) -> bool:
	if L.route_distance(at,paths)<65+margin: return true
	for fall:Vector2 in L.FALLS:
		if at.distance_to(fall)<150+margin:return true
	return false

func plant() -> void:
	var tree_art:=[ENV+"oak.png",ENV+"oak_medium.png",FOREST+"pine_crisp.png",FOREST+"oak_young.png"]
	for attempt in 4200:
		var at:=Vector2(rng.randf_range(50,3150),rng.randf_range(70,3150)).snapped(Vector2(2,2))
		if near_water(at,65) or reserved(at,38) or near_bridge(at,120):continue
		if elevation_vertices(at,1) or elevation_vertices(at-Vector2(0,180),1):continue
		var apart:=true
		for old in tree_positions:
			if at.distance_squared_to(old)<10000:apart=false;break
		if not apart:continue
		var target:Node=groups.TreesBack if at.y<1600 else groups.TreesFront
		prop(target,tree_art[rng.randi_range(0,3)],at,2,true,"Tree")
		tree_positions.append(at)
	# Banks are planted in clusters following water contours, with clear bridge mouths.
	for outline in outlines:
		for i in range(0,outline.size(),5):
			var at:Vector2=outline[i]
			var tangent:Vector2=(outline[(i+1)%outline.size()]-outline[(i-1+outline.size())%outline.size()]).normalized()
			var normal:=Vector2(tangent.y,-tangent.x)
			if near_water(at+normal*35):normal=-normal
			at+=normal*rng.randf_range(28,52)
			if near_bridge(at,55) or reserved(at,-30):continue
			var art: String=[ART+"reeds.png",ART+"river_stones.png",FOREST+"fern.png",ENV+"flowers.png"][i%4]
			prop(groups.LowVegetation,art,at,1,false,"BankPlant")
			if i%3==0:prop(groups.LowVegetation,ENV+"grass.png",at+normal*25)
	for i in 2100:
		var at:=Vector2(rng.randf_range(40,3160),rng.randf_range(60,3140))
		if near_water(at,5) or reserved(at,-25):continue
		if i%6==3 and reserved(at,30):continue
		var art:String=[ENV+"grass.png",ENV+"flowers.png",FOREST+"fern.png",BUSH,FOREST+"mushroom_brown.png",FOREST+"mushroom_glow.png"][i%6]
		prop(groups.LowVegetation,art,at,1,false,"Meadow")
	for i in 250:
		var at:=Vector2(rng.randf_range(150,3050),rng.randf_range(650,3000))
		if near_water(at) and not near_bridge(at,30):prop(groups.WaterDecorations,ART+"lily_pad.png",at,1,false,"Lily")
	for i in 95:
		var at:=Vector2(rng.randf_range(100,3100),rng.randf_range(200,3100))
		if near_water(at,45) or reserved(at,20):continue
		prop(groups.Decorations,ENV+"stone.png" if i%4 else LOG,at,1,true,"RockLog")

func points() -> void:
	var spawn:=Marker2D.new()
	spawn.name="PlayerSpawn"
	spawn.position=L.SPAWN
	add(groups.SpawnPoints,spawn)
	for i in L.HABITATS.size():
		var marker:=Marker2D.new()
		marker.name="WaterSlimeHabitat%02d"%(i+1)
		marker.position=L.HABITATS[i]
		marker.set_meta("habitat","freshwater_bank")
		marker.set_meta("reserved_radius",64)
		marker.set_meta("future_species","water_slime")
		add(groups.SlimeSpawnPoints,marker)
	for entry in [["North",Vector2(1600,70),"res://scenes/regions/FlorestaDoDespertarV2.tscn"],["South",Vector2(1780,3160),""]]:
		var marker:=Marker2D.new()
		marker.name=entry[0]
		marker.position=entry[1]
		marker.set_meta("destination",entry[2])
		add(groups.Transitions,marker)
	var poi:=[
		["Nascentes",Vector2(1260,1300),"Observar as nascentes","A água atravessa as rochas e alimenta as lagoas do vale."],
		["Lagoas",L.HABITATS[2],"Observar as lagoas","Margens tranquilas e ilhotas abrigarão os slimes de água."],
		["Jardim",Vector2(260,2050),"Observar o jardim úmido","Samambaias e flores crescem à sombra das árvores de margem."],
		["Canais",Vector2(2180,2170),"Observar os canais","Os riachos se encontram e seguem até a lagoa ao sul."],
		["Brejo",Vector2(1120,2510),"Observar o brejo","Entre os juncos, pequenas poças mantêm o solo sempre úmido."]]
	for entry in poi:
		var marker:=Marker2D.new()
		marker.name=entry[0]
		marker.position=entry[1]
		marker.set_meta("label",entry[2])
		marker.set_meta("description",entry[3])
		add(groups.PointsOfInterest,marker)

func elevations() -> void:
	make_elevations()

func elevation_vertices(at:Vector2,level:int) -> bool:
	var plateaus:=[ [Vector2(640,460),Vector2(370,190)], [Vector2(2470,460),Vector2(380,190)], [Vector2(1600,1130),Vector2(330,200)] ]
	if level==2:plateaus=[[Vector2(490,350),Vector2(145,85)],[Vector2(2610,350),Vector2(140,85)]]
	if level==3:plateaus=[[Vector2(480,305),Vector2(72,48)]]
	for data in plateaus:
		var delta:Vector2=(at-data[0])/data[1]
		if delta.length()<1.0+.04*sin(delta.angle()*3): return true
	return false

func height_value(cell:Vector2i,level:int,tall:bool) -> int:
	var snapped_cell:=Vector2i(cell.x,int(floor(cell.y/2.0))*2) if tall else cell
	if elevation_vertices(Vector2(snapped_cell)*64,level):return 1
	var above:=Vector2i(cell.x,int(floor((cell.y-1)/2.0))*2)
	if tall and elevation_vertices(Vector2(above)*64,level):return 2
	return 0

func atlas_data(file:String) -> Dictionary:
	var data:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(ART+file+".json"))
	var ts:=TileSet.new()
	ts.tile_size=Vector2i(32,32)
	var atlas:=TileSetAtlasSource.new()
	atlas.texture=load(ART+file+".png")
	atlas.texture_region_size=Vector2i(32,32)
	for tile:Dictionary in data.tileset_data.tiles:
		var bb:Dictionary=tile.bounding_box
		atlas.create_tile(Vector2i(int(bb.x)/32,int(bb.y)/32))
	ts.add_source(atlas,0)
	ResourceSaver.save(ts,ART+file+".tres")
	return {"tiles":data.tileset_data.tiles,"set":ts}

func match_tile(entries:Array,sample:Callable) -> Vector2i:
	var found:=Vector2i(-1,-1)
	var best:=-1
	for tile:Dictionary in entries:
		var specificity:=0
		var valid:=true
		for row in 4:
			var pattern:Array=tile.pattern_4x4["row_"+str(row)]
			for col in 4:
				if int(pattern[col])==255:continue
				if int(pattern[col])!=sample.call(Vector2i(col-1,row-1)):
					valid=false
					break
				specificity+=1
			if not valid:break
		if valid and specificity>best:
			best=specificity
			found=Vector2i(int(tile.bounding_box.x)/32,int(tile.bounding_box.y)/32)
	return found

func make_elevations() -> void:
	var apertures:=[Rect2(305,490,110,280),Rect2(1325,1160,110,290),Rect2(2655,480,110,260)]
	for level in [1,2,3]:
		var tall:bool=level==1
		var data:=atlas_data("cliffs_tall" if tall else "cliffs_low")
		var layer:=TileMapLayer.new()
		layer.name="ElevationLevel%d"%level
		var cliff_material:=ShaderMaterial.new()
		cliff_material.shader=load("res://scripts/world/valley_cliffs.gdshader")
		layer.material=cliff_material
		layer.tile_set=data.set
		layer.scale=Vector2(2,2)
		add(groups.Elevations,layer)
		var missing:=0
		for y in range(2,25):
			for x in range(2,49):
				var cell:=Vector2i(x,y)
				var values:=[height_value(cell,level,tall),height_value(cell+Vector2i.RIGHT,level,tall),height_value(cell+Vector2i.DOWN,level,tall),height_value(cell+Vector2i.ONE,level,tall)]
				if values==[0,0,0,0]:continue
				var sample:=func(offset:Vector2i)->int:return height_value(cell+offset,level,tall)
				var coord:=match_tile(data.tiles,sample)
				if coord.x<0:
					missing+=1
					print("NO TILE ",cell," values=",values)
					continue
				layer.set_cell(cell,0,coord)
				if values!=[1,1,1,1]:
					var pieces:Array[PackedVector2Array]=[box(Rect2(Vector2(cell)*64,Vector2(64,64)))]
					for aperture:Rect2 in apertures:
						var trimmed:Array[PackedVector2Array]=[]
						for p in pieces:trimmed.append_array(Geometry2D.clip_polygons(p,box(aperture)))
						pieces=trimmed
					for p in pieces:block(groups.Obstacles,p)
		print("Elevation ",level," tiles=",layer.get_used_cells().size()," unmatched=",missing)
	for i in apertures.size():
		var center:Vector2=apertures[i].get_center()
		var s:=Sprite2D.new()
		s.name="StoneStairs" if i<2 else "GrassRamp"
		s.texture=tex(ART+("stone_steps.png" if i<2 else "grass_ramp_flat.png"))
		s.scale=Vector2(2,2)
		s.position=Vector2(center.x,[640,1340,610][i])
		add(groups.Bridges,s)
	for i in L.FALLS.size():
		var fall:=Node2D.new()
		fall.name="Waterfall%d"%(i+1)
		fall.position=L.FALLS[i]
		add(groups.Waterfalls,fall)
		# Wet stone shoulders anchor the sheet into the terrace, not into grass.
		for side in [-1,1]:
			for tier in 4:
				var rock:=Sprite2D.new()
				rock.name="WetRockFace"
				rock.texture=tex(ART+"cliffs_tall.png")
				rock.region_enabled=true
				rock.region_rect=Rect2(98+(tier%2)*4,25,24,24)
				rock.position=Vector2(side*(51+tier%2*4),-40+tier*42)
				rock.scale=Vector2(2,2)
				rock.flip_h=side<0
				rock.modulate=Color(.77,.88,.83)
				add(fall,rock)
		var sprite:=Sprite2D.new()
		sprite.name="Cascade"
		var cascade_material:=ShaderMaterial.new()
		cascade_material.shader=load("res://scripts/world/valley_cascade.gdshader")
		sprite.material=cascade_material
		sprite.texture=tex(ART+"waterfall_medium.png")
		sprite.scale=Vector2(2,2)
		sprite.position=Vector2(0,28)
		add(fall,sprite)
		for side in [-1,1]:
			prop(fall,ART+"river_stones.png",Vector2(side*45,-54),.9,false,"LipStone")
		var foam:=Node2D.new()
		foam.name="LivingFoam"
		foam.set_script(load("res://scripts/world/waterfall_life.gd"))
		foam.shores=outlines
		foam.z_index=1
		add(fall,foam)

func water_bank_tiles() -> void:
	var data:=atlas_data("water_banks")
	var layer:=TileMapLayer.new()
	layer.name="WaterBankTiles"
	var bank_material:=ShaderMaterial.new()
	bank_material.shader=load("res://scripts/world/valley_banks.gdshader")
	bank_material.set_shader_parameter("grass_atlas",load("res://assets/tilesets/grass_dirt_v3_32x32.png"))
	bank_material.set_shader_parameter("depth_map",depth_texture)
	layer.material=bank_material
	layer.tile_set=data.set
	layer.z_index=-10
	add(world,layer)
	var vertices:Dictionary={}
	for y in 102:
		for x in 102:
			vertices[Vector2i(x,y)]=0 if near_water(Vector2(x,y)*32) else 1
	for y in 100:
		for x in 100:
			var cell:=Vector2i(x,y)
			var mask:=[vertices[cell],vertices[cell+Vector2i.RIGHT],vertices[cell+Vector2i.DOWN],vertices[cell+Vector2i.ONE]]
			if mask==[1,1,1,1] or mask==[0,0,0,0]:continue
			var coord:=match_tile(data.tiles,func(o:Vector2i)->int:return vertices.get(cell+o,1))
			if coord.x>=0:layer.set_cell(cell,0,coord)
	# Rounded source pools terminate against real boulders, not a rectangular river cap.
	for at:Vector2 in [Vector2(640,420),Vector2(2470,410),Vector2(1600,1010)]:
		for offset:Vector2 in [Vector2(-70,-12),Vector2(-35,-48),Vector2(12,-55),Vector2(58,-30)]:
			prop(groups.Decorations,ENV+"stone.png",at+offset,2,true,"SpringBoulder")
		prop(groups.LowVegetation,FOREST+"fern.png",at+Vector2(70,-45),1,false,"SpringFern")

func make_depth_texture() -> Texture2D:
	# Two-pass chamfer distance gives each shore a gradual shallow shelf.
	# Baked once into the scene; no distance scans or generated textures at runtime.
	var size:=200
	var field:=PackedFloat32Array()
	field.resize(size*size)
	for y in size:
		for x in size:field[y*size+x]=16.0 if near_water(Vector2(x+.5,y+.5)*16) else 0.0
	for y in range(1,size-1):
		for x in range(1,size-1):
			var index:=y*size+x
			field[index]=minf(field[index],minf(field[index-1]+1,minf(field[index-size]+1,minf(field[index-size-1]+1.414,field[index-size+1]+1.414))))
	for y in range(size-2,0,-1):
		for x in range(size-2,0,-1):
			var index:=y*size+x
			field[index]=minf(field[index],minf(field[index+1]+1,minf(field[index+size]+1,minf(field[index+size+1]+1.414,field[index+size-1]+1.414))))
	var image:=Image.create(size,size,false,Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var depth:=clampf(field[y*size+x]/9.0,0,1)
			image.set_pixel(x,y,Color(depth,depth,depth,1))
	return ImageTexture.create_from_image(image)

func aquatic_life() -> void:
	var life:=Node2D.new()
	life.name="UnderwaterLife"
	life.z_index=-12
	life.set_script(load("res://scripts/world/water_life.gd"))
	life.shores=outlines
	var aquatic_rng:=RandomNumberGenerator.new()
	aquatic_rng.seed=L.SEED+91
	var plants:=PackedVector2Array()
	var schools:=PackedVector2Array()
	for i in 12000:
		var at:=Vector2(aquatic_rng.randf_range(100,3100),aquatic_rng.randf_range(700,3000)).snapped(Vector2(2,2))
		if not life.is_water(at,40) or near_bridge(at,20):continue
		var islet:=false
		for island:Vector2 in [Vector2(1490,1760),Vector2(2480,2650),Vector2(2630,880)]:
			if at.distance_to(island)<145:islet=true
		if islet:continue
		if plants.size()<190:
			var spaced:=true
			for old:Vector2 in plants:
				if at.distance_to(old)<52:spaced=false;break
			if spaced:plants.append(at)
		if schools.size()<38 and life.is_water(at,62):
			var spaced:=true
			for old:Vector2 in schools:
				if at.distance_to(old)<145:spaced=false;break
			if spaced:schools.append(at)
		if plants.size()>=190 and schools.size()>=38:break
	life.plants=plants
	life.fish_centers=schools
	add(world,life)
	print("Aquatic ecosystem plants=",plants.size()," fish=",schools.size()*3)
