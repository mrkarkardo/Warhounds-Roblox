-- Jackson selected the lobby armory for the B4 detail pass.
-- The supplied lock reports RELEASED. This single short additive operation targets environment decor.
assert(game.PlaceId==76780441857243 and not game:GetService("RunService"):IsRunning())
local armory=workspace.Lobby.Armory
local tableTop=armory.Shop.TableTop.TableTop
assert(not armory:FindFirstChild("MaintenanceDetails"))
assert(tableTop.Position:FuzzyEq(Vector3.new(2000,3.2,88),0.002), "Table moved")
local V=Vector3.new
local rgb=Color3.fromRGB
local rubber=rgb(96,101,100)
local metal=rgb(132,140,138)
local steel=rgb(105,113,110)
local brass=rgb(159,127,72)
local canvas=rgb(140,141,117)
local paper=rgb(204,195,170)
local orange=rgb(173,126,53)
local ABS=Vector3.new(2000,0,0)
local top=tableTop.Position.Y+tableTop.Size.Y/2
local folder=Instance.new("Folder")
folder.Name="MaintenanceDetails"
local function model(name,x,y,z,yaw)
 local m=Instance.new("Model")
 m.Name=name
 m.WorldPivot=CFrame.new(ABS+V(x,y,z))*CFrame.Angles(0,yaw or 0,0)
 m.Parent=folder
 return m
end
local function piece(m,name,cf,size,color,material,shape)
 local p=Instance.new("Part")
 p.Name=name
 p.Size=size
 p.CFrame=m:GetPivot()*cf
 p.Color=color
 p.Material=material or Enum.Material.SmoothPlastic
 p.Shape=shape or Enum.PartType.Block
 p.Anchored=true
 p.CanCollide=false
 p.CanQuery=false
 p.CanTouch=false
 p.CastShadow=false
 p.TopSurface=Enum.SurfaceType.Smooth
 p.BottomSurface=Enum.SurfaceType.Smooth
 p.Parent=m
 return p
end
local function box(m,name,x,y,z,sx,sy,sz,col,material)
 return piece(m,name,CFrame.new(x,y,z),V(sx,sy,sz),col,material)
end
local function rod(m,name,a,b,diameter,color,material)
 local cf=CFrame.lookAt((a+b)*0.5,b)*CFrame.Angles(0,math.pi/2,0)
 return piece(m,name,cf,V((b-a).Magnitude,diameter,diameter),color,material,Enum.PartType.Cylinder)
end

local mat=model("ServiceMatAndTools",2.65,top,86.13,math.rad(-3))
box(mat,"RubberMat",0,0.031,0,3.60,0.082,1.63,rubber,Enum.Material.Rubber)
for _,z in {-0.741,0.741} do
 box(mat,"RaisedEdge",0,0.072,z,3.40,0.041,0.082,steel,Enum.Material.Rubber)
end
box(mat,"FoldedShopCloth",-1.05,0.128,-0.23,0.98,0.115,0.82,canvas,Enum.Material.Fabric)
box(mat,"ClothFold",-1.10,0.201,-0.12,0.76,0.06,0.63,rgb(157,151,126),Enum.Material.Fabric)
box(mat,"PartsTray",0.98,0.105,-0.20,1.01,0.096,0.70,steel,Enum.Material.Metal)
for _,x in {0.56,1.40} do box(mat,"TrayLip",x,0.178,-0.20,0.075,0.17,0.54,metal,Enum.Material.Metal) end
for _,z in {-0.477,0.077} do box(mat,"TrayLip",0.98,0.183,z,0.75,0.15,0.069,metal,Enum.Material.Metal) end
rod(mat,"DriverHandle",V(-0.24,0.148,0.36),V(0.23,0.148,0.40),0.16,orange,Enum.Material.Rubber)
rod(mat,"DriverShank",V(0.18,0.149,0.397),V(0.61,0.149,0.433),0.052,metal,Enum.Material.Metal)
rod(mat,"BrushHandle",V(-0.49,0.115,-0.25),V(0.27,0.115,-0.31),0.078,brass,Enum.Material.Wood)
box(mat,"BrushBristles",0.40,0.128,-0.32,0.29,0.105,0.11,canvas,Enum.Material.Fabric)

local clipboard=model("InventoryClipboard",-2.62,top,86.20,math.rad(12))
box(clipboard,"Board",0,0.045,0,1.54,0.109,1.08,rgb(145,112,80),Enum.Material.Wood)
box(clipboard,"PaperStack",0,0.109,0.045,1.34,0.033,0.87,paper)
box(clipboard,"SpringClip",0,0.153,-0.382,0.62,0.095,0.205,metal,Enum.Material.Metal)
for i=1,4 do
 box(clipboard,"PrintedRule",0.03,0.13,-0.22+i*0.123,0.88,0.030,0.014,rgb(161,153,131))
end
rod(clipboard,"GreasePencil",V(-0.48,0.151,0.30),V(0.39,0.151,0.39),0.055,orange)
rod(clipboard,"PencilCap",V(0.36,0.152,0.387),V(0.49,0.152,0.40),0.069,steel)

local ear=model("HearingProtection",3.66,top,89.78,math.rad(14))
for _,side in {-1,1} do
 local x=side*0.52
 rod(ear,"EarCup",V(x-0.095,0.30,0),V(x+0.095,0.30,0),0.59,canvas,Enum.Material.SmoothPlastic)
 rod(ear,"CupCushion",V(x-side*0.19,0.30,0),V(x-side*0.082,0.30,0),0.535,rubber,Enum.Material.Rubber)
 box(ear,"Yoke",x,0.57,0,0.105,0.33,0.19,steel,Enum.Material.Metal)
end
local arc={V(-0.52,0.63,0),V(-0.43,0.91,0),V(-0.23,1.065,0),V(0.21,1.08,0),V(0.43,0.91,0),V(0.52,0.63,0)}
for i=1,#arc-1 do rod(ear,"Headband",arc[i],arc[i+1],0.15,rubber,Enum.Material.Rubber) end

local case=model("ClosedFieldKit",-26,2.4,72,math.rad(193.4))
box(case,"CaseShell",0,0.34,0,2.79,0.71,1.91,canvas,Enum.Material.Metal)
box(case,"Lid",0,0.737,0.008,2.87,0.16,1.98,rgb(158,153,121),Enum.Material.Metal)
for _,x in {-1.13,1.13} do
 box(case,"CornerReinforcement",x,0.425,-0.939,0.26,0.50,0.14,steel,Enum.Material.Metal)
end
for _,x in {-0.83,0.83} do
 box(case,"Latch",x,0.602,-0.985,0.22,0.33,0.13,metal,Enum.Material.Metal)
end
for _,x in {-0.46,0.46} do box(case,"HandleBracket",x,0.36,-1.025,0.16,0.13,0.19,steel,Enum.Material.Metal) end
rod(case,"FoldedHandle",V(-0.48,0.35,-1.13),V(0.48,0.35,-1.13),0.11,rubber,Enum.Material.Rubber)

local parts={}
for _,p in folder:GetDescendants() do
 if p:IsA("BasePart") then
  assert(p.Anchored and not p.CanCollide and not p.CanQuery and not p.CanTouch and not p.CastShadow)
  table.insert(parts,p)
 end
end
assert(#parts<=48)
-- Check near-coplanar same-facing block faces, including rotated props.
local new,old={},{}
local function bounds(p)
 if not p:IsA("Part") or p.Shape~=Enum.PartType.Block or p.Transparency>=0.95 then return end
 local cf=p.CFrame
 return {p=p,c=cf.Position,axes={cf.RightVector,cf.UpVector,cf.LookVector},h={p.Size.X/2,p.Size.Y/2,p.Size.Z/2},radius=p.Size.Magnitude/2}
end
for _,p in folder:GetDescendants() do
 if p:IsA("BasePart") then
  assert(p.Anchored and not p.CanCollide and not p.CanQuery and not p.CanTouch and not p.CastShadow)
  local a=bounds(p)
  if a then table.insert(new,a) end
 end
end
for _,p in armory:GetDescendants() do
 if not p:IsDescendantOf(folder) then
  local a=bounds(p)
  if a then table.insert(old,a) end
 end
end
local found={}
local function compare(a,b)
 local offset=b.c-a.c
 if offset.Magnitude>a.radius+b.radius+0.02 then return end
 for i,n in a.axes do
  for j,m in b.axes do
   if math.abs(n:Dot(m))>0.999999 then
    local separation=offset:Dot(n)
    local plus=math.abs(a.h[i]-b.h[j]-separation)
    local minus=math.abs(b.h[j]-a.h[i]-separation)
    if math.min(plus,minus)<0.012 then
     local u,v=i%3+1,(i+1)%3+1
     local w,x=j%3+1,(j+1)%3+1
     local overlap=true
     for _,axis in {a.axes[u],a.axes[v],b.axes[w],b.axes[x]} do
      local ra=a.h[u]*math.abs(axis:Dot(a.axes[u]))+a.h[v]*math.abs(axis:Dot(a.axes[v]))
      local rb=b.h[w]*math.abs(axis:Dot(b.axes[w]))+b.h[x]*math.abs(axis:Dot(b.axes[x]))
      if ra+rb-math.abs(axis:Dot(offset))<0.016 then overlap=false;break end
     end
     if overlap then table.insert(found,{a.p:GetFullName(),b.p:GetFullName(),i,j,math.min(plus,minus)}) end
    end
   end
  end
 end
end
for i,a in new do
 for j=i+1,#new do compare(a,new[j]) end
 for _,b in old do compare(a,b) end
end
assert(#found==0, game:GetService("HttpService"):JSONEncode(found))
folder.Parent=armory
return string.format("Added %d non-colliding detail parts across %d Models in %s",#parts,#folder:GetChildren(),folder:GetFullName())
