{ This file is a part of Map editor for VCMI project

  Copyright (C) 2013 Alexander Shishkin alexvins@users.sourceforge,net

  This source is free software; you can redistribute it and/or modify it under
  the terms of the GNU General Public License as published by the Free
  Software Foundation; either version 2 of the License, or (at your option)
  any later version.

  This code is distributed in the hope that it will be useful, but WITHOUT ANY
  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
  FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
  details.

  A copy of the GNU General Public License is available on the World Wide Web
  at <http://www.gnu.org/copyleft/gpl.html>. You can also obtain it by writing
  to the Free Software Foundation, Inc., 59 Temple Place - Suite 330, Boston,
  MA 02111-1307, USA.
}
unit Map;

{$I compilersetup.inc}

interface

uses
  Classes, SysUtils, Math, LCLIntf, gvector, gpriorityqueue, editor_types,
  editor_consts, terrain, editor_classes, editor_graphics, objects,
  object_options, lists_manager;

const
  MAP_DEFAULT_SIZE = 36;
  MAP_DEFAULT_LEVELS = 1;

  MAP_PLAYER_COUNT = 8;

type
  TVCMIMap = class;

  IMapWriter = interface
    procedure Write(AStream: TStream; AMap: TVCMIMap);
  end;


  //TMapDiscreteSize = (S = 36, M = 72, L = 108, XL = 144);

  TMapCreateParams = object
  public
    Width: Integer;
    Height: Integer;
    Levels: Integer;
  end;

  {$push}
  {$m+}

  { TCustomHero }

  TCustomHero = class (TCollectionItem)
  private
    FName: string;
    FPortrait: THeroID;
    procedure SetName(AValue: string);
    procedure SetPortrait(AValue: THeroID);
  published
    property Portrait:THeroID read FPortrait write SetPortrait nodefault;
    property Name: string read FName write SetName;
  end;

  { TCustomHeroes }

  TCustomHeroes = class (specialize TGArrayCollection<TCustomHero>)
  public
    constructor Create;
    destructor Destroy; override;
  end;

  { TPlayerAttr }

  TPlayerAttr = class
  private
    FAITactics: TAITactics;
    FAllowedFactions: TFactions;
    FAreAllowerFactionsSet: Boolean;
    FCanComputerPlay: boolean;
    FCanHumanPlay: boolean;
    FCustomHeroes: TCustomHeroes;
    FGenerateHeroAtMainTown: boolean;
    FHasMainTown: boolean;
    FIsFactionRandom: boolean;
    FMainHeroName: TLocalizedString;
    FMainHeroPortrait: TCustomID;
    FMainTownL: Integer;
    FMainTownType: TFactionID;
    FMainTownX: Integer;
    FMainTownY: Integer;
    FRandomHero: Boolean;
    FMainHeroClass: THeroClassID;
    FTeamId: Integer;
    procedure SetAITactics(AValue: TAITactics);
    procedure SetAreAllowerFactionsSet(AValue: Boolean);
    procedure SetCanComputerPlay(AValue: boolean);
    procedure SetCanHumanPlay(AValue: boolean);
    procedure SetGenerateHeroAtMainTown(AValue: boolean);
    procedure SetHasMainTown(AValue: boolean);
    procedure SetIsFactionRandom(AValue: boolean);
    procedure SetMainHeroName(AValue: TLocalizedString);
    procedure SetMainHeroPortrait(AValue: TCustomID);
    procedure SetMainTownL(AValue: Integer);
    procedure SetMainTownType(AValue: TFactionID);
    procedure SetMainTownX(AValue: Integer);
    procedure SetMainTownY(AValue: Integer);
    procedure SetRandomHero(AValue: Boolean);
    procedure SetMainHeroClass(AValue: THeroClassID);
    procedure SetTeamId(AValue: Integer);
  public
    constructor Create;
    destructor Destroy; override;
  published
    property AITactics: TAITactics read FAITactics write SetAITactics;
    property AreAllowerFactionsSet: Boolean read FAreAllowerFactionsSet write SetAreAllowerFactionsSet; //???
    property AllowedFactions: TFactions read FAllowedFactions;
    property IsFactionRandom: boolean read FIsFactionRandom write SetIsFactionRandom;

    property CanComputerPlay: boolean read FCanComputerPlay write SetCanComputerPlay;
    property CanHumanPlay: boolean read FCanHumanPlay write SetCanHumanPlay;

    property CustomHeroes: TCustomHeroes read FCustomHeroes;
    property GenerateHeroAtMainTown: boolean read FGenerateHeroAtMainTown write SetGenerateHeroAtMainTown;
    property HasMainTown: boolean read FHasMainTown write SetHasMainTown;

    property MainTownType: TFactionID read FMainTownType write SetMainTownType;
    property MainTownX: Integer read FMainTownX write SetMainTownX;
    property MainTownY: Integer read FMainTownY write SetMainTownY;
    property MainTownL: Integer read FMainTownL write SetMainTownL;


    property MainHeroClass: THeroClassID read FMainHeroClass write SetMainHeroClass;
    property MainHeroPortrait:TCustomID read FMainHeroPortrait write SetMainHeroPortrait;
    property MainHeroName:TLocalizedString read FMainHeroName write SetMainHeroName;

    property RandomHero:Boolean read FRandomHero write SetRandomHero;
    property TeamId: Integer read FTeamId write SetTeamId default 0;
  end;

  { TPlayerAttrs }

  TPlayerAttrs = class
  private
    FColors : array[TPlayerColor] of TPlayerAttr;
  public
    constructor Create;
    destructor Destroy; override;

    function GetAttr(color: Integer): TPlayerAttr;

  published
    property Red:TPlayerAttr index Integer(TPlayerColor.Red) read GetAttr ;
    property Blue:TPlayerAttr index Integer(TPlayerColor.Blue) read GetAttr;
    property Tan:TPlayerAttr index Integer(TPlayerColor.Tan) read GetAttr;
    property Green:TPlayerAttr index Integer(TPlayerColor.Green) read GetAttr;

    property Orange:TPlayerAttr index Integer(TPlayerColor.Orange) read GetAttr;
    property Purple:TPlayerAttr index Integer(TPlayerColor.Purple) read GetAttr;
    property Teal:TPlayerAttr index Integer(TPlayerColor.Teal) read GetAttr;
    property Pink:TPlayerAttr index Integer(TPlayerColor.Pink) read GetAttr;
  end;

  { TRumor }

  TRumor = class(TCollectionItem)
  private
    FName: TLocalizedString;
    FText: TLocalizedString;
    procedure SetName(AValue: TLocalizedString);
    procedure SetText(AValue: TLocalizedString);
  published
    property Name: TLocalizedString read FName write SetName;
    property Text: TLocalizedString read FText write SetText;
  end;

  { TRumors }

  TRumors = class(specialize TGArrayCollection<TRumor>)
  public
    constructor Create;
  end;

  { TMapObjectTemplate }

  TMapObjectTemplate = class (TCollectionItem)
  private
    FDef: TDef;
  private
    FAllowedTerrains: TTerrainTypes;
    FID: TObjectTypeID;
    FMask: TStringList;
    FAnimation: string;
    FMenuTerrains: TTerrainTypes;
    FSubID: TCustomID;
    FZIndex: Integer;
    function GetMask: TStrings;
    function GetTID: integer;
    procedure SetAllowedTerrains(AValue: TTerrainTypes);
    procedure SetAnimation(AValue: string);
    procedure SetID(AValue: TObjectTypeID);
    procedure SetMenuTerrains(AValue: TTerrainTypes);
    procedure SetSubID(AValue: TCustomID);
    procedure SetZIndex(AValue: Integer);
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;

    //TODO: refactor this temproary solution
    procedure FillFrom(AOther: TObjTemplate);
  published

    property TID: integer read GetTID;

    property Animation:string read FAnimation write SetAnimation;

    property Mask:TStrings read GetMask;
    property AllowedTerrains: TTerrainTypes read FAllowedTerrains write SetAllowedTerrains default ALL_TERRAINS;
    property MenuTerrains: TTerrainTypes read FMenuTerrains write SetMenuTerrains default ALL_TERRAINS;

    property Id: TObjectTypeID read FID write SetID nodefault;
    property SubId: TCustomID read FSubID write SetSubID nodefault;

    property ZIndex: Integer read FZIndex write SetZIndex default 0;
  end;

  { TMapObjectTemplates }

  TMapObjectTemplates = class (specialize TGArrayCollection<TMapObjectTemplate>)
  private
    FMap: TVCMIMap;
  public
    constructor Create(AMap: TVCMIMap);
  end;

  { TMapTile }

  PMapTile = ^TMapTile;

  TMapTile = object
  strict private
    //start binary compatible with H3 part
    FTerType: TTerrainType;
    FTerSubtype: UInt8;
    FRiverType: UInt8;
    FRiverDir: UInt8;
    FRoadType: UInt8;
    FRoadDir: UInt8;
    FFlags: UInt8;
    //end binary compatible with H3 part
    FOwner: TPlayer;
    procedure SetFlags(AValue: UInt8);
    procedure SetRiverDir(AValue: UInt8);
    procedure SetRiverType(AValue: UInt8);
    procedure SetRoadDir(AValue: UInt8);
    procedure SetRoadType(AValue: UInt8);
    procedure SetTerSubtype(AValue: UInt8);
    procedure SetTerType(AValue: TTerrainType);
  public
    constructor Create();

    procedure Render(mgr: TTerrainManager; X,Y: Integer); inline;
    procedure RenderRoad(mgr: TTerrainManager; X,Y: Integer); inline;

    property TerType: TTerrainType read FTerType write SetTerType;
    property TerSubType: UInt8 read FTerSubtype write SetTerSubtype;

    property RiverType:UInt8 read FRiverType write SetRiverType;
    property RiverDir:UInt8 read FRiverDir write SetRiverDir;
    property RoadType:UInt8 read FRoadType write SetRoadType;
    property RoadDir:UInt8 read FRoadDir write SetRoadDir;
    property Flags:UInt8 read FFlags write SetFlags;
  end;

  { TMapObject }

  TMapObject = class (TCollectionItem)
  strict private
    FLastFrame: Integer;
    FLastTick: DWord;
    FOptions: TObjectOptions;

    FTemplate: TMapObjectTemplate;
    FL: integer;
    FTemplateID: integer;
    FX: integer;
    FY: integer;
    function GetPlayer: TPlayer; inline;
    procedure Render(Frame:integer; Ax,Ay: integer);
    procedure SetL(AValue: integer);
    procedure SetTemplateID(AValue: integer);
    procedure SetX(AValue: integer);
    procedure SetY(AValue: integer);

    function GetMap:TVCMIMap;
  protected
    procedure Changed;
  public
    constructor Create(ACollection: TCollection); override;
    destructor Destroy; override;
    property Template: TMapObjectTemplate read FTemplate;
    procedure RenderStatic(); inline;
    procedure RenderStatic(X,Y: integer); inline;
    procedure RenderAnim(); inline;

    procedure RenderSelectionRect; inline;

    function CoversTile(ALevel, AX, AY: Integer): boolean;

    function HasOptions: boolean;

  published
    property X:integer read FX write SetX;
    property Y:integer read FY write SetY;
    property L:integer read FL write SetL;

    property TemplateID: integer read FTemplateID write SetTemplateID;

    property Options: TObjectOptions read FOptions stored HasOptions;
  end;

  { TObjPriorityCompare }

  TObjPriorityCompare = class
  public
    class function c(a,b: TMapObject): boolean;
  end;

  TMapObjectQueue = specialize TPriorityQueue<TMapObject, TObjPriorityCompare>;

  { TMapObjects }

  TMapObjects = class (specialize TGArrayCollection<TMapObject>)
  private
    FMap: TVCMIMap;
  protected
    function GetOwner: TPersistent; override;

  public
    constructor Create(AOwner: TVCMIMap);

    property Map: TVCMIMap read FMap;
  end;

  TMapEnvironment = record
    tm: TTerrainManager;
    lm: TListsManager;
  end;

  ///WIP, MULTILEVEL MAP

  { TMapLevel }

  TMapLevel = class(TCollectionItem)
  strict private
    FHeight: Integer;
    FOwner: TVCMIMap;
    FTerrain: array of array of TMapTile; //X, Y
    FObjects: TMapObjects; //todo: use it
    FWidth: Integer;
    function GetTile(X, Y: Integer): PMapTile; inline;
    procedure SetHeight(AValue: Integer);
    procedure SetOwner(AValue: TVCMIMap);
    procedure SetWidth(AValue: Integer);

    procedure Resize;
  public
    destructor Destroy; override;

    property Tile[X, Y: Integer]: PMapTile read GetTile;

    property Owner: TVCMIMap read FOwner write SetOwner;
  published
    property Height: Integer read FHeight write SetHeight;
    property Width: Integer read FWidth write SetWidth;
  end;

  { TMapLevels }

  TMapLevels = class(specialize TGNamedCollection<TMapLevel>)

  end;

  { TVCMIMap }

  TVCMIMap = class (TPersistent, IFPObserver)
  private
    FCurrentLevel: Integer;
    FDescription: TLocalizedString;
    FDifficulty: TDifficulty;

    FHeight: Integer;
    FHeroLevelLimit: Integer;
    FName: TLocalizedString;
    FObjects: TMapObjects;
    FPlayerAttributes: TPlayerAttrs;
    FTemplates: TMapObjectTemplates;
    FTerrainManager: TTerrainManager;
    FListsManager: TListsManager;
    FWigth: Integer;
    FLevels: TMapLevels;

    FAllowedSpells: TStringList;
    FAllowedAbilities: TStringList;

    FRumors: TRumors;

    FIsDirty: boolean;

    procedure Changed;
    function GetAllowedAbilities: TStrings;
    function GetAllowedSpells: TStrings;
    function GetCurrentLevel: Integer; inline;
    function GetLevelCount: Integer;
    procedure RecreateTerrainArray;

    procedure AttachTo(AObserved: IFPObserved);
    procedure FPOObservedChanged(ASender: TObject;
      Operation: TFPObservedOperation; Data: Pointer);

    procedure SetCurrentLevel(AValue: Integer);
    procedure SetDifficulty(AValue: TDifficulty);
    procedure SetHeroLevelLimit(AValue: Integer);
    procedure SetDescription(AValue: TLocalizedString);
    procedure SetName(AValue: TLocalizedString);

  public
    //create with default params
    constructor CreateDefault(env: TMapEnvironment);
    //create with specified params and set default options
    constructor Create(env: TMapEnvironment; Params: TMapCreateParams);
    //create for deserialize
    constructor CreateExisting(env: TMapEnvironment; Params: TMapCreateParams);
    destructor Destroy; override;

    procedure SetTerrain(X, Y: Integer; TT: TTerrainType); overload; //set default terrain
    procedure SetTerrain(Level, X, Y: Integer; TT: TTerrainType; TS: UInt8; mir: UInt8 =0); overload; //set concete terrain
    procedure FillLevel(TT: TTerrainType);

    function GetTile(Level, X, Y: Integer): PMapTile;

    function IsOnMap(Level, X, Y: Integer): boolean;

    //Left, Right, Top, Bottom - clip rect in Tiles
    procedure RenderTerrain(Left, Right, Top, Bottom: Integer);
    procedure RenderObjects(Left, Right, Top, Bottom: Integer);

    property CurrentLevel: Integer read GetCurrentLevel write SetCurrentLevel;

    procedure SaveToStream(ADest: TStream; AWriter: IMapWriter);

    property IsDirty: Boolean read FIsDirty;

    property TerrainManager: TTerrainManager read FTerrainManager;
    property ListsManager: TListsManager read FListsManager;

    procedure SelectObjectsOnTile(Level, X, Y: Integer; dest: TMapObjectQueue);
  published
    property Height: Integer read FHeight;
    property Width: Integer read FWigth;
    property Levels: Integer read GetLevelCount;

    property Name:TLocalizedString read FName write SetName;
    property Description:TLocalizedString read FDescription write SetDescription;

    property Difficulty: TDifficulty read FDifficulty write SetDifficulty;
    property HeroLevelLimit: Integer read FHeroLevelLimit write SetHeroLevelLimit;

    property PlayerAttributes: TPlayerAttrs read FPlayerAttributes;

    property Rumors: TRumors read FRumors;

    property AllowedSpells: TStrings read GetAllowedSpells;
    property AllowedAbilities: TStrings read GetAllowedAbilities;

  public //manual streamimg
    property Templates: TMapObjectTemplates read FTemplates;
    property Objects: TMapObjects read FObjects;
  end;

  {$pop}

implementation

uses FileUtil, editor_str_consts, root_manager, editor_utils;

{ TRumor }

procedure TRumor.SetName(AValue: TLocalizedString);
begin
  if FName = AValue then Exit;
  FName := AValue;
end;

procedure TRumor.SetText(AValue: TLocalizedString);
begin
  if FText = AValue then Exit;
  FText := AValue;
end;

{ TRumors }

constructor TRumors.Create;
begin
  inherited Create;
end;

{ TObjPriorityCompare }

class function TObjPriorityCompare.c(a, b: TMapObject): boolean;
begin
  Result := (a.Template.ZIndex > b.Template.ZIndex)
    or(
      (a.Template.ZIndex = b.Template.ZIndex)
      and (a.Y > b.Y)
     );
end;

{ TMapObject }

procedure TMapObject.Changed;
begin
  Collection.BeginUpdate;
  Collection.EndUpdate;
end;

function TMapObject.CoversTile(ALevel, AX, AY: Integer): boolean;
var
  w: UInt32;
  h: UInt32;
begin
  //TODO: use MASK
  w := Template.FDef.Width div TILE_SIZE;
  h := Template.FDef.Height div TILE_SIZE;
  Result := (FL = ALevel)
    and (X>=AX) and (Y>=AY)
    and (X-w<AX) and (Y-h<AY);
end;

constructor TMapObject.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FLastFrame := 0;
  FTemplateID := -1;
end;

destructor TMapObject.Destroy;
begin
  FreeAndNil(FOptions);
  inherited Destroy;
end;

function TMapObject.GetPlayer: TPlayer;
begin
  if Options.MayBeOwned then
  begin
    Result := Options.Owner;
  end
  else
  begin
    Result := TPlayer.none;
  end;
end;

function TMapObject.HasOptions: boolean;
begin
  Result := Assigned(FOptions) and (FOptions.ClassType <> TObjectOptions);
end;

procedure TMapObject.Render(Frame: integer; Ax, Ay: integer);
var
  owner : TPlayer;
begin
  owner := GetPlayer;
  Template.FDef.RenderO(Frame, Ax,Ay,GetPlayer);

  if (owner <> TPlayer.none) and (TObj(Template.Id) in [TObj.HERO, TObj.RANDOM_HERO, TObj.HERO_PLACEHOLDER]) then
  begin
    RootManager.GraphicsManger.GetHeroFlagDef(owner).RenderO(0, Ax, Ay);
  end;
end;

procedure TMapObject.RenderAnim;
var
  new_tick: DWord;
begin
  new_tick := GetTickCount;

  if abs(new_tick - FLastTick) > 155 then
  begin
    Inc(FLastFrame);

    FLastTick := new_tick;

    if FLastFrame >= Template.FDef.FrameCount then
      FLastFrame := 0;
  end;

  Render(FLastFrame,(x+1)*TILE_SIZE,(y+1)*TILE_SIZE);
end;

procedure TMapObject.RenderSelectionRect;
begin
  FTemplate.FDef.RenderBorder(FX,FY);
end;

procedure TMapObject.RenderStatic;
begin
  Render(FLastFrame, (x+1)*TILE_SIZE,(y+1)*TILE_SIZE);
end;

procedure TMapObject.RenderStatic(X, Y: integer);
begin
  Render(FLastFrame, x,y);
end;

procedure TMapObject.SetL(AValue: integer);
begin
  if not GetMap.IsOnMap(AValue, FX,FY) then exit;

  if FL = AValue then Exit;

  FL := AValue;
  Changed;
end;

procedure TMapObject.SetTemplateID(AValue: integer);
begin
  if FTemplateID = AValue then Exit; //dont remove

  FTemplate := GetMap().FTemplates.Items[AValue];

  FTemplateID := AValue;

  FreeAndNil(FOptions);

  FOptions := object_options.CreateByID(FTemplate.Id,FTemplate.SubId);
  Changed;
end;

procedure TMapObject.SetX(AValue: integer);
begin
  if not GetMap.IsOnMap(FL, AValue,FY) then exit;
  if FX = AValue then Exit;
  FX := AValue;
  Changed;
end;

procedure TMapObject.SetY(AValue: integer);
begin
  if not GetMap.IsOnMap(FL, FX,AValue) then exit;
  if FY = AValue then Exit;
  FY := AValue;
  Changed;
end;

function TMapObject.GetMap: TVCMIMap;
begin
  Result := (Collection as TMapObjects).Map;
end;

{ TMapObjects }

constructor TMapObjects.Create(AOwner: TVCMIMap);
begin
  inherited Create;
  FMap  := AOwner;
end;

function TMapObjects.GetOwner: TPersistent;
begin
  Result := FMap;
end;

{ TMapObjectTemplates }

constructor TMapObjectTemplates.Create(AMap: TVCMIMap);
begin
  inherited Create;
  FMap := AMap;
end;

{ TMapObjectTemplate }

constructor TMapObjectTemplate.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FMask := TStringList.Create;
  FAllowedTerrains := ALL_TERRAINS;

end;

destructor TMapObjectTemplate.Destroy;
begin
  FMask.Free;
  inherited Destroy;
end;

procedure TMapObjectTemplate.FillFrom(AOther: TObjTemplate);
begin
  FAnimation := AOther.Filename;
  FDef := AOther.Def;

  FID := AOther.Typ;
  FSubID := AOther.SubType;
  FZIndex := AOther.IsOverlay * Z_INDEX_OVERLAY;
end;

function TMapObjectTemplate.GetMask: TStrings;
begin
  Result := FMask;
end;

function TMapObjectTemplate.GetTID: integer;
begin
  Result := inherited ID;
end;

procedure TMapObjectTemplate.SetAllowedTerrains(AValue: TTerrainTypes);
begin
  if FAllowedTerrains = AValue then Exit;
  FAllowedTerrains := AValue;
end;

procedure TMapObjectTemplate.SetAnimation(AValue: string);
var
  gm: TGraphicsManager;
begin
  AValue := SetDirSeparators(ExtractFileNameWithoutExt(Trim(UpperCase(AValue))));
  if FAnimation = AValue then Exit;
  FAnimation := AValue;

  gm := (Collection as TMapObjectTemplates).FMap.FTerrainManager.GraphicsManager; //TODO: refactor
  FDef := gm.GetGraphics(FAnimation);
  //todo: load and check
end;

procedure TMapObjectTemplate.SetID(AValue: TObjectTypeID);
begin
  if FID = AValue then Exit;
  FID := AValue;
end;

procedure TMapObjectTemplate.SetMenuTerrains(AValue: TTerrainTypes);
begin
  if FMenuTerrains = AValue then Exit;
  FMenuTerrains := AValue;
end;

procedure TMapObjectTemplate.SetSubID(AValue: TCustomID);
begin
  if FSubID = AValue then Exit;
  FSubID := AValue;
end;

procedure TMapObjectTemplate.SetZIndex(AValue: Integer);
begin
  if FZIndex = AValue then Exit;
  FZIndex := AValue;
end;

{ TCustomHeroes }

constructor TCustomHeroes.Create;
begin
  inherited Create();
end;

destructor TCustomHeroes.Destroy;
begin
  inherited Destroy;
end;

{ TCustomHero }

procedure TCustomHero.SetName(AValue: string);
begin
  if FName = AValue then Exit;
  FName := AValue;
end;

procedure TCustomHero.SetPortrait(AValue: THeroID);
begin
  if FPortrait = AValue then Exit;
  FPortrait := AValue;
end;

constructor TPlayerAttr.Create;
begin
  FAllowedFactions := TFactions.Create;
  FCustomHeroes := TCustomHeroes.Create;
end;

destructor TPlayerAttr.Destroy;
begin
  FCustomHeroes.Free;
  FAllowedFactions.Free;
  inherited Destroy;
end;

procedure TPlayerAttr.SetAITactics(AValue: TAITactics);
begin
  if FAITactics = AValue then Exit;
  FAITactics := AValue;
end;

procedure TPlayerAttr.SetAreAllowerFactionsSet(AValue: Boolean);
begin
  if FAreAllowerFactionsSet = AValue then Exit;
  FAreAllowerFactionsSet := AValue;
end;

procedure TPlayerAttr.SetCanComputerPlay(AValue: boolean);
begin
  if FCanComputerPlay = AValue then Exit;
  FCanComputerPlay := AValue;
end;

procedure TPlayerAttr.SetCanHumanPlay(AValue: boolean);
begin
  if FCanHumanPlay = AValue then Exit;
  FCanHumanPlay := AValue;
end;

procedure TPlayerAttr.SetGenerateHeroAtMainTown(AValue: boolean);
begin
  if FGenerateHeroAtMainTown = AValue then Exit;
  FGenerateHeroAtMainTown := AValue;
end;

procedure TPlayerAttr.SetHasMainTown(AValue: boolean);
begin
  if FHasMainTown = AValue then Exit;
  FHasMainTown := AValue;
end;

procedure TPlayerAttr.SetIsFactionRandom(AValue: boolean);
begin
  if FIsFactionRandom = AValue then Exit;
  FIsFactionRandom := AValue;
end;

procedure TPlayerAttr.SetMainTownL(AValue: Integer);
begin
  if FMainTownL = AValue then Exit;
  FMainTownL := AValue;
end;

procedure TPlayerAttr.SetMainTownType(AValue: TFactionID);
begin
  if FMainTownType = AValue then Exit;
  FMainTownType := AValue;
end;

procedure TPlayerAttr.SetMainTownX(AValue: Integer);
begin
  if FMainTownX = AValue then Exit;
  FMainTownX := AValue;
end;

procedure TPlayerAttr.SetMainTownY(AValue: Integer);
begin
  if FMainTownY = AValue then Exit;
  FMainTownY := AValue;
end;

procedure TPlayerAttr.SetRandomHero(AValue: Boolean);
begin
  if FRandomHero = AValue then Exit;
  FRandomHero := AValue;
end;

procedure TPlayerAttr.SetTeamId(AValue: Integer);
begin
  if FTeamId = AValue then Exit;
  FTeamId := AValue;
end;

procedure TPlayerAttr.SetMainHeroClass(AValue: THeroClassID);
begin
  if FMainHeroClass = AValue then Exit;
  FMainHeroClass := AValue;
end;

procedure TPlayerAttr.SetMainHeroName(AValue: TLocalizedString);
begin
  if FMainHeroName = AValue then Exit;
  FMainHeroName := AValue;
end;

procedure TPlayerAttr.SetMainHeroPortrait(AValue: TCustomID);
begin
  if FMainHeroPortrait = AValue then Exit;
  FMainHeroPortrait := AValue;
end;

{ TPlayerAttrs }

constructor TPlayerAttrs.Create;
var
  color: TPlayerColor;
begin
  for color in TPlayerColor do
    FColors[color] := TPlayerAttr.Create;
end;

destructor TPlayerAttrs.Destroy;
var
  color: TPlayerColor;
begin
  for color in TPlayerColor do
    FColors[color].Free;
  inherited Destroy;
end;

function TPlayerAttrs.GetAttr(color: Integer): TPlayerAttr;
begin
  Result := FColors[TPlayerColor(color)];
end;

{ TMapTile }

constructor TMapTile.Create;
begin
  FTerType := TTerrainType.rock;
  FTerSubtype := 0;

  FRiverType:=0;
  FRiverDir:=0;
  FRoadType:=0;
  FRoadDir:=0;
  FFlags:=0;
  FOwner := TPlayer.NONE;
end;

procedure TMapTile.Render(mgr: TTerrainManager; X, Y: Integer);
begin
  mgr.Render(FTerType,FTerSubtype,X,Y,Flags);

  mgr.RenderRiver(TRiverType(FRiverType),FRiverDir,X,Y,Flags);
end;

procedure TMapTile.RenderRoad(mgr: TTerrainManager; X, Y: Integer);
begin
  mgr.RenderRoad(TRoadType(FRoadType),FRoadDir,X,Y,Flags);
end;

procedure TMapTile.SetFlags(AValue: UInt8);
begin
  if FFlags = AValue then Exit;
  FFlags := AValue;
end;

procedure TMapTile.SetRiverDir(AValue: UInt8);
begin
  if FRiverDir = AValue then Exit;
  FRiverDir := AValue;
end;

procedure TMapTile.SetRiverType(AValue: UInt8);
begin
  if FRiverType = AValue then Exit;
  FRiverType := AValue;
end;

procedure TMapTile.SetRoadDir(AValue: UInt8);
begin
  if FRoadDir = AValue then Exit;
  FRoadDir := AValue;
end;

procedure TMapTile.SetRoadType(AValue: UInt8);
begin
  if FRoadType = AValue then Exit;
  FRoadType := AValue;
end;

procedure TMapTile.SetTerSubtype(AValue: UInt8);
begin
  if FTerSubtype = AValue then Exit;
  FTerSubtype := AValue;
end;

procedure TMapTile.SetTerType(AValue: TTerrainType);
begin
  if FTerType = AValue then Exit;
  FTerType := AValue;
end;


{ TMapLevel }

destructor TMapLevel.Destroy;
//var
//  X: SizeInt;
//  Y: SizeInt;
begin
  //for X := 0 to Length(FTerrain) - 1 do
  //begin
  //  for Y := 0 to Length(FTerrain[X]) - 1 do
  //  begin
  //    FTerrain[X][Y].Free();
  //  end;
  //end;
  inherited Destroy;
end;

function TMapLevel.GetTile(X, Y: Integer): PMapTile;
begin
  Result :=@FTerrain[x,y];
end;

procedure TMapLevel.Resize;
var
  tt: TTerrainType;
  X: Integer;
  Y: Integer;
begin
  Assert(Height>=0, 'Invalid height');
  Assert(Width>=0, 'Invalid width');
  if (Height=0) or (Width=0) then Exit;


    tt := FOwner.FTerrainManager.GetDefaultTerrain(Index);

    SetLength(FTerrain,FWidth);
    for X := 0 to FWidth - 1 do
    begin
      SetLength(FTerrain[X],FHeight);
      for Y := 0 to FHeight - 1 do
      begin
        FTerrain[X][Y].Create();
        FTerrain[X][Y].TerType :=  tt;
        FTerrain[X][Y].TerSubtype := FOwner.FTerrainManager.GetRandomNormalSubtype(tt);
      end;
    end;

end;

procedure TMapLevel.SetHeight(AValue: Integer);
begin
  if FHeight = AValue then Exit;
  FHeight := AValue;
  Resize();
end;

procedure TMapLevel.SetOwner(AValue: TVCMIMap);
begin
  if FOwner=AValue then Exit;
  FOwner:=AValue;
end;

procedure TMapLevel.SetWidth(AValue: Integer);
begin
  if FWidth = AValue then Exit;
  FWidth := AValue;
  Resize();
end;

{ TVCMIMap }

procedure TVCMIMap.AttachTo(AObserved: IFPObserved);
begin
  AObserved.FPOAttachObserver(Self);
end;

procedure TVCMIMap.Changed;
begin
  FIsDirty := True;
end;

constructor TVCMIMap.Create(env: TMapEnvironment; Params: TMapCreateParams);
begin
  CreateExisting(env,Params);

  FListsManager.SpellInfos.FillWithAllIds(FAllowedSpells);
  FListsManager.SkillInfos.FillWithAllIds(FAllowedAbilities);
end;

constructor TVCMIMap.CreateDefault(env: TMapEnvironment);
var
  params: TMapCreateParams;
begin
  params.Height := MAP_DEFAULT_SIZE;
  params.Width := MAP_DEFAULT_SIZE;
  params.Levels := MAP_DEFAULT_LEVELS;

  Create(env,params);

end;

constructor TVCMIMap.CreateExisting(env: TMapEnvironment;
  Params: TMapCreateParams);
var
  ALevel: TMapLevel;
begin
  FTerrainManager := env.tm;
  FListsManager := env.lm;

  FHeight := Params.Height;
  FWigth := Params.Width;
  FLevels := TMapLevels.Create;

  ALevel := FLevels.Add;
  ALevel.Owner := Self;
  ALevel.Width := FWigth;
  ALevel.Height:=FHeight;
  ALevel.DisplayName := 'Surface';

  if Params.Levels>1 then
  begin

    ALevel := FLevels.Add;
    ALevel.Owner := Self;
    ALevel.Width := FWigth;
    ALevel.Height:=FHeight;
    ALevel.DisplayName := 'Underground';

  end;

  RecreateTerrainArray;
  CurrentLevel := 0;

  Name := rsDefaultMapName;

  FIsDirty := False;

  FAllowedAbilities := CrStrList;
  FAllowedSpells := CrStrList;

  FPlayerAttributes := TPlayerAttrs.Create;
  FTemplates := TMapObjectTemplates.Create(self);
  FObjects := TMapObjects.Create(Self);
  FRumors := TRumors.Create;
  AttachTo(FObjects);
end;

destructor TVCMIMap.Destroy;
begin
  FAllowedAbilities.Free;
  FAllowedSpells.Free;

  FRumors.Free;
  FObjects.Free;
  FTemplates.Free;
  FPlayerAttributes.Free;
  FLevels.Free;
  inherited Destroy;
end;

procedure TVCMIMap.FillLevel(TT: TTerrainType);
var
  x: Integer;
  Y: Integer;
begin
  for x := 0 to FWigth - 1 do
  begin
    for Y := 0 to FHeight - 1 do
    begin
      SetTerrain(x,y,tt);
    end;

  end;

end;

procedure TVCMIMap.FPOObservedChanged(ASender: TObject;
  Operation: TFPObservedOperation; Data: Pointer);
begin
  if (ASender = FObjects) then
  begin
    case Operation of
      ooChange,ooAddItem,ooDeleteItem: FIsDirty := true ;
    end;
  end;
end;

function TVCMIMap.GetAllowedAbilities: TStrings;
begin
  Result := FAllowedAbilities;
end;

function TVCMIMap.GetAllowedSpells: TStrings;
begin
  Result := FAllowedSpells;
end;

function TVCMIMap.GetCurrentLevel: Integer;
begin
  Result := FCurrentLevel;
end;

function TVCMIMap.GetLevelCount: Integer;
begin
  Result := FLevels.Count;
end;

function TVCMIMap.GetTile(Level, X, Y: Integer): PMapTile;
begin
  Result := FLevels[Level].Tile[x,y]//todo: check
end;

function TVCMIMap.IsOnMap(Level, X, Y: Integer): boolean;
begin
  Result := (Level >=0)
  and (Level < Levels)
  and (x>=0) and (x<Width)
  and (y>=0) and (y<Height);
end;

procedure TVCMIMap.RecreateTerrainArray;
var
  Level: Integer;
  X: Integer;
  Y: Integer;

  tt: TTerrainType;
begin
  //DestroyTiles();
  //
  //SetLength(FTerrain, FLevels);
  //
  //for Level := 0 to FLevels-1 do
  //begin
  //
  //  tt := FTerrainManager.GetDefaultTerrain(Level);
  //
  //  SetLength(FTerrain[Level],FWigth);
  //  for X := 0 to FWigth - 1 do
  //  begin
  //    SetLength(FTerrain[Level, X],FHeight);
  //    for Y := 0 to FHeight - 1 do
  //    begin
  //      FTerrain[Level][X][Y] := TMapTile.Create();
  //      FTerrain[Level][X][Y].TerType :=  tt;
  //      FTerrain[Level][X][Y].TerSubtype := FTerrainManager.GetRandomNormalSubtype(tt);
  //    end;
  //  end;
  //end;
end;

procedure TVCMIMap.RenderTerrain(Left, Right, Top, Bottom: Integer);
var
  i: Integer;
  j: Integer;
begin

  Right := Min(Right, FWigth - 1);
  Bottom := Min(Bottom, FHeight - 1);

  for i := Left to Right do
  begin
    for j := Top to Bottom do
    begin
      GetTile(FCurrentLevel,i,j)^.Render(FTerrainManager,i,j);
    end;
  end;

  Top := Max(0,Top-1);

  for i := Left to Right do
  begin
    for j := Top to Bottom do
    begin
      GetTile(FCurrentLevel,i,j)^.RenderRoad(FTerrainManager,i,j);
    end;
  end;



end;

procedure TVCMIMap.RenderObjects(Left, Right, Top, Bottom: Integer);
var
  i: Integer;
  o: TMapObject;

  FQueue : TMapObjectQueue;
begin

  FQueue := TMapObjectQueue.Create;

  for i := 0 to FObjects.Count - 1 do
  begin
    o := TMapObject(FObjects.Items[i]);
    if o.L <> CurrentLevel then
      Continue;

    if (o.X < Left)
      or (o.Y < Top)
      or (o.X - 8 > Right)
      or (o.y - 6 > Bottom)
      then Continue; //todo: use visisblity mask

    FQueue.Push(o);

  end;

  while not FQueue.IsEmpty do
  begin
    o := FQueue.Top;
    o.RenderAnim;
    FQueue.Pop;
  end;

  FQueue.Free;
end;

procedure TVCMIMap.SaveToStream(ADest: TStream; AWriter: IMapWriter);
begin
  AWriter.Write(ADest,Self);
  FIsDirty := False;
end;

procedure TVCMIMap.SelectObjectsOnTile(Level, X, Y: Integer;
  dest: TMapObjectQueue);
var
  o: TMapObject;
  i: Integer;
begin
  //TODO: use mask

  for i := 0 to FObjects.Count - 1 do
  begin
    o := FObjects[i];

    if o.CoversTile(Level,x,y) then
    begin
      dest.Push(o);
    end;
  end;
end;

procedure TVCMIMap.SetCurrentLevel(AValue: Integer);
begin
  if FCurrentLevel = AValue then Exit; //TODO: check
  FCurrentLevel := AValue;
end;

procedure TVCMIMap.SetDescription(AValue: TLocalizedString);
begin
  if FDescription = AValue then Exit;
  FDescription := AValue;
  Changed;
end;

procedure TVCMIMap.SetDifficulty(AValue: TDifficulty);
begin
  if FDifficulty = AValue then Exit;
  FDifficulty := AValue;
  Changed;
end;

procedure TVCMIMap.SetHeroLevelLimit(AValue: Integer);
begin
  if FHeroLevelLimit = AValue then Exit;
  FHeroLevelLimit := AValue;
  Changed;
end;

procedure TVCMIMap.SetName(AValue: TLocalizedString);
begin
  if FName = AValue then Exit;
  FName := AValue;
  Changed;
end;

procedure TVCMIMap.SetTerrain(Level, X, Y: Integer; TT: TTerrainType;
  TS: UInt8; mir: UInt8);
var
  t: PMapTile;
begin
  t := GetTile(Level,X,Y);
  t^.TerType := TT;
  t^.TerSubtype := TS;
  t^.Flags := (t^.Flags and $FC) or (mir and 3);

  Changed;
end;

procedure TVCMIMap.SetTerrain(X, Y: Integer; TT: TTerrainType);
begin
  SetTerrain(CurrentLevel,X,Y,TT,FTerrainManager.GetRandomNormalSubtype(TT));
end;

end.

