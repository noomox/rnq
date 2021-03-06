{
  This file is part of R&Q.
  Under same license
}
unit RnQLangs;
{$I ForRnQConfig.inc}

{$I NoRTTI.inc}

interface
uses
  Windows, Classes, SysUtils,
  {$IFDEF LANGDEBUG}
  iniFiles,
  {$ENDIF}
  Generics.Collections,
  RDFileUtil;

type
  ToLangInfo = Class(TObject)
   public
//  Tthemeinfo = record
     fn, subFile, desc: string;
//     isUTF: Boolean;
//     Ver: byte;
    end;
   aLangInfo = array of ToLangInfo;

//  TLangList = THashedStringList;
  TLangList = TDictionary<String, String>;
  TResLangList = TDictionary<Integer, String>;

type
  TMethodHook = class
  private
    aOriginal: packed array[ 0..4 ] of byte;
    pOldProc, pNewProc: pointer;
    pPosition: PByteArray;
  public
    constructor Create( pOldProc, pNewProc: pointer );
    destructor Destroy; override;
  end;


type
  TRnQLang = class
   private
    class var RecStrNameIdMap: TResLangList;
    class var aMethodHook: TMethodHook;
   public
    class constructor  CreateLangs;
    class destructor DestroyLangs;
    class procedure RegisterProcedures(aOriginalProcedure, aNewProcedure: pointer);
    class function LoadResString(ResStringRec: PResStringRec): String;
   private
//    LangPath: TThemePath;
    LangsStr: TLangList;
  {$IFDEF LANGDEBUG}
//    hLangsStr: TLangList;
    hLangsStr: THashedStringList;
  {$ENDIF}

    langFN0, langFN1: String;
//    langIsUTF: Boolean;
    function TranslateString(const Str: AnsiString): String; overload; {$IFDEF HAS_INLINE} inline; {$ENDIF HAS_INLINE}// overload;//cdecl;
 {$IFDEF UNICODE}
    function TranslateString(const Str: UnicodeString): String; overload; {$IFDEF HAS_INLINE} inline; {$ENDIF HAS_INLINE}// overload;//cdecl;
 {$ENDIF UNICODE}
    Procedure LangAddStr(const k: String; const v: String; Mas: TLangList);
  {$IFDEF LANGDEBUG}
    Procedure DebugAddStr(const k: String; const v: String);
  {$ENDIF}
    function  fileIsUTF(const fn: String): Boolean;
   public
//    constructor LoadLang(p_fn: String; p_isUTFLang: Boolean);
    constructor Create;
    destructor Destroy; OverRide;
//    function Trans(const key: AnsiString; const args:array of const):string; overload;
//    function Trans(const key: AnsiString):string; overload;

   {$IFDEF UNICODE}
//    function Trans(const key: UnicodeString; const args: array of const): string; overload;
//    function Trans(const key: UnicodeString): string; overload;
   {$ENDIF UNICODE}

//    Procedure loadLanguageFile(fn: String; isUTFLang: Boolean);
    function loadLanguageFile2(fn: String; ts: TThemeSourcePath; isUTFLang: Boolean): Boolean;

    procedure ClearLanguage;
    procedure resetLanguage;
//    procedure loadLanguage;
    procedure loadLanguage2(f: ToLangInfo);
    procedure loadLastLanguage;

    procedure ClearLang;
    procedure resetLang;
  end;

  function getTranslation(const key: AnsiString; const args: array of const): String; overload;
  function getTranslation(const key: AnsiString): String;  overload;

 {$IFDEF UNICODE}
  function getTranslation(const key: UnicodeString; const args: array of const): string; overload;
  function getTranslation(const key: UnicodeString): string; overload;
 {$ENDIF UNICODE}

  procedure refreshLangList(pLangFileMask: String; pOnlyFileNames: Boolean; appPath: String; mainPath: String = '');
  procedure ClearLanglist;

  procedure LoadSomeLanguage(pLangFileMask: String; appPath: String; mainPath: String = '');
  procedure ClearLanguage;
var
  useLang: Boolean = false;

  gLangFile, gLangSubFile: String;

const
  c_Int_Lang_FN = 'internal';

implementation
 uses
   StrUtils, Masks,
   RDGlobal, RDUtils,
 {$IFDEF RNQ}
   RnQLangFrm,
   RQlog,
   RQUtil,
 {$ENDIF RNQ}
 {$IFDEF USE_ZIP}
  RnQZip,
 {$ENDIF USE_ZIP}
 {$IFDEF UNICODE}
   AnsiStrings,
 {$ENDIF UNICODE}
  RnQStrings;

var
  langList: aLangInfo;
  LangVar: TRnQLang;
{  lang: array of record
    key, text: string;
    end;
  alreadyLoaded: array of string;  // keep track of loaded modules
}

{Replacement for System.LoadResString}
function NewLoadResString(ResStringRec: PResStringRec): String;
var
  Buffer: array [0..4095] of char;
begin
  if ResStringRec = nil then Exit;
  if ResStringRec.Identifier >= 64 * 1024 then
  begin
    Result := PChar(ResStringRec.Identifier);
  end
  else
  begin
    Result := TRnQLang.LoadResString(ResStringRec);
  end;
end;



//  PrefStr: THashedStringList;
{
Procedure LangAddStr(const k, v: AnsiString; Mas: THashedStringList);
var
  so: TPUStrObj;
  i: Integer;
begin
  i := Mas.IndexOf(k);
  if i>=0 then
    begin
      so := TPUStrObj(Mas.Objects[i]);
      FreeMemory(so.Str);
      so.Str := NIL;
    end
   else
    so := TPUStrObj.Create;
  so.Str := GetMemory(Length(v)+1);
  StrCopy(so.Str, PChar(v));
  if i<0 then
    Mas.AddObject(k, so);
//    Mas.Names
end;

constructor TRnQLang.LoadLang(p_fn: String; p_isUTFLang: Boolean);
begin
  LangsStr := THashedStringList.Create;
  loadLanguageFile(p_fn, p_isUTFLang);
end;
}
  {Hookup aNewProcedure on aOriginalProcedure}
class procedure TRnQLang.RegisterProcedures(aOriginalProcedure, aNewProcedure: pointer);
begin
    if Assigned(aOriginalProcedure) and Assigned(aNewProcedure) then
      aMethodHook := TMethodHook.Create( aOriginalProcedure, aNewProcedure);
end;

class constructor TRnQLang.CreateLangs;
begin
  aMethodHook := nil;
  RecStrNameIdMap := TResLangList.Create;
  RegisterProcedures(@System.LoadResString, @NewLoadResString);
end;

class destructor TRnQLang.DestroyLangs;
begin
  aMethodHook.Free;
  aMethodHook := NIL;
  RecStrNameIdMap.Free;
  RecStrNameIdMap := NIL;
end;

constructor TRnQLang.Create;
begin
//  LangsStr := THashedStringList.Create;
  LangsStr := TLangList.Create;
  resetLanguage;
end;

destructor TRnQLang.Destroy;
begin
  FreeAndNil(LangsStr);
end;

procedure TRnQLang.resetLanguage;
begin
 if Assigned(LangsStr) then
   LangsStr.Clear;
 RecStrNameIdMap.Clear;
end; // resetLanguage

procedure TRnQLang.ClearLanguage;
  {$IFDEF LANGDEBUG}
var
//  sr: TsearchRec;
//  ls: String;
  i: Integer;
  so: TPUStrObj;
  {$ENDIF LANGDEBUG}
begin
//  useLang := False;
  {$IFDEF LANGDEBUG}
   if lang_debug then
    if Assigned(hLangsStr) then
     begin
      hLangsStr.SaveToFile('RnQ.Translate.txt');
      for I := 0 to hLangsStr.Count - 1 do
       begin
        so := TPUStrObj(hLangsStr.Objects[i]);
        hLangsStr.Objects[i] := NIL;
        FreeMemory(so.Str);
        so.Free;
       end;
      hLangsStr.Clear;
      FreeAndNil(hLangsStr);
     end;
  {$ENDIF}
  if Assigned(LangsStr) then
    begin
{
     for I := 0 to LangsStr.Count - 1 do
      begin
       so := TPUStrObj(LangsStr.Objects[i]);
       LangsStr.Objects[i] := NIL;
       FreeMemory(so.Str);
       so.Free;
      end;
}
     LangsStr.Clear;
     FreeAndNil(LangsStr);
    end;
end;

function TRnQLang.loadLanguageFile2(fn: string; ts: TThemeSourcePath; isUTFLang: Boolean): Boolean;
{
  function fullpath(const fn: string): string;
   var
    s1: String;
  begin
    if mainPath > '' then
      s1 := mainPath + fn
     else
      s1 := fn;
    if ansipos(':', fn)=0 then
      result := appPath + s1
     else
      result := s1
  end;
}
var
  k, v: RawByteString;
  kU, vU: String;
  i, j: Integer;
  txt: RawByteString;
begin
  Result := False;
 ts.path := ts.path + ExtractFilePath(fn);
 ts.path := includeTrailingPathDelimiter(ts.path);
 if IsPathDelimiter(ts.path, 1) then
   Delete(ts.path, 1, 1);
 fn := ExtractFileName(fn);
 if fn = '' then
  Exit;
  Result := ExistsFile(ts, fn);
  if not Result then
    Exit;
 txt := loadfile(ts, fn);
 while txt>'' do
  begin
    k := chopline(txt);
//   par := trim(line);
    if k = '' then
      continue;
    if k[1] <> '[' then
     begin
 {$IFDEF UNICODE}
      v := AnsiStrings.trim(chop(RawByteString('='), k));
      k := AnsiStrings.trim(k);
 {$ELSE nonUNICODE}
      v := trim(chop('=', k));
      k := trim(k);
 {$ENDIF UNICODE}
      if v='include' then
       begin
         kU := UnUTF(k);
         loadLanguageFile2(kU, ts, isUTFLang);
       end;
      continue;
     end;
    delete(k, 1, 1);
    i := 1;
    repeat
 {$IFDEF UNICODE}
     j := AnsiStrings.PosEx(']', k, i+1);
 {$ELSE nonUNICODE}
     j := PosEx(']', k, i+1);
 {$ENDIF UNICODE}
     if j > 0 then
      i := j;
    until j <= 0;
 //   i := AnsiPos(']', k);
    if i>1 then
      delete(k, i, length(k));
 {$IFDEF UNICODE}
    k := AnsiStrings.trim(k);
    kU := UnUTF(k);
 {$ELSE nonUNICODE}
    k := trim(k);
    kU := trim(k);
 {$ENDIF UNICODE}
    v := chopline(txt);
    if isUTFLang then
     begin
//      vv := UnUTF(v);
//      vv := UTF8ToString(UTF8String(Pointer(v)));
      vU := UTF8ToStr(v);
      vU := TrimRight(vU);
     end
    else
     begin
       vU := UnUTF(TrimRight(v));
     end;
    if vU <> '' then
      LangAddStr(kU, vU, LangsStr);

  end;
end;

(*
Procedure TRnQLang.loadLanguageFile(fn: String; isUTFLang: Boolean);
  function fullpath(fn: string): string;
  begin if ansipos(':',fn)=0 then result:=myPath+fn else result:=fn end;
var
  f: text;
  k,v: RawByteString;
  vv: String;
  i, j: Integer;
begin
  assignfile(f, fn);
  reset(f);
 try
  while not eof(f) do
   begin
    readln(f,k);
    if k = '' then continue;
    if k[1] <> '[' then
     begin
 {$IFDEF UNICODE}
      v := AnsiStrings.trim(chop(RawByteString('='),k));
      k := AnsiStrings.trim(k);
 {$ELSE nonUNICODE}
      v:= trim(chop('=',k));
      k := trim(k);
 {$ENDIF UNICODE}
      if v='include' then
       begin
         loadLanguageFile(fullpath(k), isUTFLang);
       end;
      continue;
     end;
    delete(k,1,1);
    i := 1;
    repeat
 {$IFDEF UNICODE}
     j := AnsiStrings.PosEx(']', k, i+1);
 {$ELSE nonUNICODE}
     j := PosEx(']', k, i+1);
 {$ENDIF UNICODE}
     if j > 0 then
      i := j;
    until j <= 0;
 //   i := AnsiPos(']', k);
    if i>1 then
      delete(k,i,length(k));
 {$IFDEF UNICODE}
    k := AnsiStrings.trim(k);
 {$ELSE nonUNICODE}
    k := trim(k);
 {$ENDIF UNICODE}
    readln(f,v);
    if isUTFLang then
     begin
//      vv := UnUTF(v);
//      vv := UTF8ToString(UTF8String(Pointer(v)));
      vv := UTF8ToStr(v);
      vv := TrimRight(vv);
     end
    else
     begin
       vv := TrimRight(v);
     end;
    if vv <> '' then
      LangAddStr(k, vv, LangsStr);
   end;
 finally
  CloseFile(F);
 end;
end;

procedure TRnQLang.loadLanguage;
var
  sr:TsearchRec;
//  ls: String;
  i, k: Integer;
begin
  loggaEvt('loading language: ');
  useLang := False;
  LangsStr := NIL;
  {$IFDEF LANGDEBUG}
   if lang_debug then
     hLangStr := THashedStringList.Create;
  {$ENDIF}
  if findFirst(MyPath+'RnQ*.utflng', faAnyFile, sr) = 0 then
    begin
     LangsStr := THashedStringList.Create;
     LangsStr.Sorted := false;
//     LangsStr.Sorted := True;
//     LangStr.CaseSensitive := False;
     LangsStr.CaseSensitive := True;
//     LangIsUnicode := True;
     loadLanguageFile(MyPath + sr.name, True);
     LangsStr.Sorted := True;
     FindClose(sr);
     useLang := True;
    end
   else
    if findFirst(MyPath+'RnQ*.lng', faAnyFile, sr) = 0 then
      begin
       LangsStr := THashedStringList.Create;
//       LangStr.Sorted := false;
       LangsStr.Sorted := True;
//       LangStr.CaseSensitive := False;
       LangsStr.CaseSensitive := True;
//       LangIsUnicode := False;
       loadLanguageFile(MyPath + sr.name, False);
       LangsStr.Sorted := True;
       FindClose(sr);
       useLang := True;
      end;
//  LangStr.Sort;
   {$IFDEF LANGDEBUG}
  lang_debug := lang_debug and useLang;
   {$ENDIF LANGDEBUG}
  if useLang and Assigned(LangsStr) then
  for i := low(not2Translate) to High(not2Translate) do
   begin
     k := LangsStr.IndexOf(not2Translate[i]);
     if k >=0 then
      begin
        FreeMemory(TPUStrObj(LangsStr.Objects[k]).Str);
        TPUStrObj(LangsStr.Objects[k]).Free;
        LangsStr.Objects[k] := NIL;
       LangsStr.Delete(k);
      end;
   {$IFDEF LANGDEBUG}
     if lang_debug then
      begin
       k := hLangStr.IndexOf(not2Translate[i]);
       if k >=0 then
        begin
         FreeMemory(TPUStrObj(hLangStr.Objects[k]).Str);
         TPUStrObj(hLangStr.Objects[k]).Free;
         hLangStr.Objects[k] := NIL;
         hLangStr.Delete(k);
        end;
      end;
   {$ENDIF LANGDEBUG}
   end;
  {$IFDEF LANGDEBUG}
   if lang_debug then
     hLangStr.Sorted := True;
  {$ENDIF}

  loggaEvt('language loaded');
end;
*)

procedure TRnQLang.loadLastLanguage;
var
  f: ToLangInfo;
begin
  f := ToLangInfo.Create;
  f.fn := langFN0;
  f.subFile := langFN1;
//  f.isUTF := langIsUTF;
  try
    loadLanguage2(f);
   finally
    f.Free;
  end;
end;

procedure TRnQLang.loadLanguage2(f: ToLangInfo);
var
   {$IFDEF LANGDEBUG}
  k: Integer;
   {$ENDIF LANGDEBUG}
  i: Integer;
  pt: TThemeSourcePath;
  fn: String;
  isUTF: Boolean;
begin
 {$IFDEF RNQ}
  loggaEvtS('loading language: ');
 {$ENDIF RNQ}

  langFN0 := f.fn;
  langFN1 := f.subFile;
//  langIsUTF := f.isUTF;

  useLang := False;
  LangsStr := NIL;
  {$IFDEF LANGDEBUG}
   if lang_debug then
     hLangsStr := THashedStringList.Create;
  {$ENDIF}
  if FileExists(f.fn) then
    begin
     if f.subFile = '' then
       begin
         pt.pathType := pt_path;
         pt.path := ExtractFilePath(f.fn);
         fn := f.fn;
       end
      else
       begin
         pt.pathType := pt_zip;
         pt.ArcFile := f.fn;
         fn := f.subFile;
         pt.zp := TZipFile.Create;
         pt.zp.LoadFromFile(pt.ArcFile);
       end;
     isUTF := fileIsUTF(fn);

     LangsStr := TLangList.Create;
{
     LangsStr.Sorted := false;
//     LangsStr.Sorted := True;
//     LangStr.CaseSensitive := False;

     LangsStr.CaseSensitive := True;
}
     useLang := loadLanguageFile2(fn, pt, isUTF);
     if (pt.pathType = pt_zip) and  Assigned(pt.zp) then
       FreeAndNil(pt.zp);
//     LangsStr.Sorted := True;
//     useLang := True;
    end;
   {$IFDEF LANGDEBUG}
  lang_debug := lang_debug and useLang;
   {$ENDIF LANGDEBUG}
  if useLang and Assigned(LangsStr) then
  for i := low(not2Translate) to High(not2Translate) do
   begin
     LangsStr.Remove(String(not2Translate[i]));
{     k := LangsStr.IndexOf(not2Translate[i]);
     if k >=0 then
      begin
        FreeMemory(TPUStrObj(LangsStr.Objects[k]).Str);
        TPUStrObj(LangsStr.Objects[k]).Free;
        LangsStr.Objects[k] := NIL;
       LangsStr.Delete(k);
      end;
}
   {$IFDEF LANGDEBUG}
     if lang_debug then
      begin
       k := hLangsStr.IndexOf(not2Translate[i]);
       if k >= 0 then
        begin
         FreeMemory(TPUStrObj(hLangsStr.Objects[k]).Str);
         TPUStrObj(hLangsStr.Objects[k]).Free;
         hLangsStr.Objects[k] := NIL;
         hLangsStr.Delete(k);
        end;
      end;
   {$ENDIF LANGDEBUG}
   end;
  {$IFDEF LANGDEBUG}
   if lang_debug then
     hLangsStr.Sorted := True;
  {$ENDIF}

 {$IFDEF RNQ}
  loggaEvtS('language loaded');
 {$ENDIF RNQ}
end;

Function TRnQLang.TranslateString(const Str: AnsiString): String;
var
//  Res: String;
//  i: Integer;
  s0, s: String;
begin
  s0 := String(Str);
    if LangsStr.TryGetValue(s0, s) then
      Result := s
     else
      Result := s0;
(*
// if not useLang then
//    Result := Str
//  else
   begin
    Result := '';
     i := LangsStr.IndexOf(Str);
     if i >= 0 then
      begin
       Result := StrPas(TPUStrObj(LangsStr.Objects[i]).Str);
//       if LangIsUnicode then
//         Result := unUTF(Result);
      end
     else
      begin
   //    LangAddStr(Str, Str, LangStr);
     {$IFDEF LANGDEBUG}
      if lang_debug then
       begin
        i := hLangStr.IndexOf(Str);
        if i < 0 then
         PrefAddStr(Str, '', hLangStr);
       end;
     {$ENDIF}
       Result := Str;
      end;
   end;
*)
end;

 {$IFDEF UNICODE}
Function TRnQLang.TranslateString(const Str: UnicodeString): String;
var
//  Res: String;
//  i: Integer;
  s: String;
begin
  if LangsStr.TryGetValue(Str, s) then
    Result := s
   else
    begin
      Result := Str;

     {$IFDEF LANGDEBUG}
      if lang_debug then
       begin
        if hLangsStr.IndexOf(Str) < 0 then
          DebugAddStr(Str, '');
       end;
     {$ENDIF}
    end;
(*
// if not useLang then
//    Result := Str
//  else
   begin
    Result := '';
     i := LangsStr.IndexOf(Str);
     if i >= 0 then
      begin
       Result := StrPas(TPUStrObj(LangsStr.Objects[i]).Str);
//       if LangIsUnicode then
//         Result := unUTF(Result);
      end
     else
      begin
   //    LangAddStr(Str, Str, LangStr);
     {$IFDEF LANGDEBUG}
      if lang_debug then
       begin
        i := hLangsStr.IndexOf(Str);
        if i < 0 then
         PrefAddStr(Str, '', hLangStr);
       end;
     {$ENDIF}
       Result := Str;
      end;
   end;
*)
end;
 {$ENDIF UNICODE}

Procedure TRnQLang.LangAddStr(const k: String; const v: String; Mas: TLangList);
//var
//  so: TPUStrObj;
//  i: Integer;
begin
  Mas.AddOrSetValue(k, v);
(*
  i := Mas.IndexOf(k);
  if i>=0 then
    begin
      so := TPUStrObj(Mas.Objects[i]);
      FreeMemory(so.Str);
//      FreeMem(so.Str);
      so.Str := NIL;
    end
   else
    so := TPUStrObj.Create;
//  so.Str := GetMemory(Length(v)+1);
  so.Str := AllocMem((Length(v)+1)*SizeOf(Char));
{$IFNDEF UNICODE}
  StrCopy(so.Str, PChar(v));
{$ELSE UNICODE}
  StrCopy(PWideChar(so.Str), PWideChar(v));
{$ENDIF UNICODE}
  if i<0 then
    Mas.AddObject(k, so);
*)
end;

     {$IFDEF LANGDEBUG}
Procedure TRnQLang.DebugAddStr(const k: String; const v: String);
var
  so: TPUStrObj;
  i: Integer;
begin
  i := hLangsStr.IndexOf(k);
  if i>=0 then
    begin
      so := TPUStrObj(hLangsStr.Objects[i]);
      FreeMemory(so.Str);
//      FreeMem(so.Str);
      so.Str := NIL;
    end
   else
    so := TPUStrObj.Create;
//  so.Str := GetMemory(Length(v)+1);
  so.Str := AllocMem((Length(v)+1)*SizeOf(Char));
{$IFNDEF UNICODE}
  StrCopy(so.Str, PChar(v));
{$ELSE UNICODE}
  StrCopy(PWideChar(so.Str), PWideChar(v));
{$ENDIF UNICODE}
  if i<0 then
    hLangsStr.AddObject(k, so);
end;
     {$ENDIF LANGDEBUG}

function TRnQLang.fileIsUTF(const fn: String): Boolean;
begin
  Result := ExtractFileExt(fn) = '.utflng';
end;

procedure TRnQLang.resetLang;
//var
//  i: Integer;
//  so: TPUStrObj;
begin
  if Assigned(LangsStr) then
    begin
(*
     for I := 0 to LangsStr.Count - 1 do
      begin
       so := TPUStrObj(LangsStr.Objects[i]);
       LangsStr.Objects[i] := NIL;
       FreeMemory(so.Str);
       so.Free;
      end;
*)
     LangsStr.Clear;
    end;
end; // resetLanguage

procedure TRnQLang.ClearLang;
begin
  if Assigned(LangsStr) then
    begin
     resetLang;
     FreeAndNil(LangsStr);
    end;
end;

class function TRnQLang.LoadResString(ResStringRec: PResStringRec): String;
var
  Buffer: array [0..4095] of char;
  s: String;
begin
  if ResStringRec = nil then Exit;
  if ResStringRec.Identifier >= 64 * 1024 then
  begin
    Result := PChar(ResStringRec.Identifier);
  end
  else
  begin
    if RecStrNameIdMap.TryGetValue(ResStringRec^.Identifier, Result) then
    begin
      Exit;
    end
    else
    begin
      SetString(s, Buffer,
        LoadString(FindResourceHInstance(ResStringRec.Module^),
          ResStringRec.Identifier, Buffer, SizeOf(Buffer)));
      if Assigned(LangVar) then
        Result := LangVar.TranslateString(s)
       else
        Result := s;
      RecStrNameIdMap.Add(ResStringRec^.Identifier, Result);
    end;
  end;
end;


//////////////////////////////////////////////////////////////////////////
function getTranslation(const key: AnsiString): string;
begin
  if useLang and Assigned(LangVar) then
    result := LangVar.TranslateString(key)
   else
    result := String(key);
  result := ansiReplaceStr(result, '\n', #13);
end; // getTranslation

function getTranslation(const key: Ansistring; const args: array of const): String;
//var
//  s: extended;
begin
  if useLang and Assigned(LangVar) then
    begin
      result := LangVar.TranslateString(key);
    end
   else
    Result := String(key);

  if Length(args) > 0 then
   try
    result := format(result, args);
   except

   end;
  result := ReplaceStr(result, '\n', #13);
//result := ansiReplaceStr(result, '\s', ' ');
end; // getTranslation

 {$IFDEF UNICODE}
function getTranslation(const key: String): string;
begin
  if useLang and Assigned(LangVar) then
    result := LangVar.TranslateString(key)
   else
     Result := key;
  result := ansiReplaceStr(result,'\n', #13);
end; // getTranslation

function getTranslation(const key: string; const args: array of const):string;
//var
//  s : extended;
begin
  if useLang and Assigned(LangVar) then
    result := LangVar.TranslateString(key)
   else
     Result := key;
  if Length(args) > 0 then
   try
    result:=format(result, args);
   except

   end;
  result:=ansiReplaceStr(result,'\n',#13);
//result:=ansiReplaceStr(result,'\s',' ');
end; // getTranslation
 {$ENDIF UNICODE}


procedure refreshLangList(pLangFileMask: String; pOnlyFileNames: Boolean; appPath: String; mainPath: String = '');
 procedure ProcessFile(Const fn, subfile: String; s: RawByteString; isUTF: Boolean);
 var
  line, k, v, section: RawByteString;
  procedure InternalprocessTheme(var ati: aLangInfo);
  var
    n:integer;
  begin
      n := Length(ati);
      setlength(ati, n+1);
      ati[n] := ToLangInfo.Create;
      ati[n].fn:=fn;
      ati[n].subFile:=subfile;
//      ati[n].isUTF := isUTF;
      section:='';

      while s>'' do
        begin
        line := chopline(s);
        if (line>'') and (line[1]='[') then
          begin
          line := trim(line);
          if line[length(line)]=']' then
            section := copy(line, 2, length(line)-2);
          continue;
          end;
        v := trim(line);
        k := AnsiLowerCase(trim(chop('=', v)));
        v := trim(v);
        if section='' then
         begin
          // if k = 'logo'  then ati[n].logo := v;
          // if k = 'title' then ati[n].title := UnUTF(v);
          if k = 'desc'  then
            ati[n].desc := ansiReplaceStr(UnUTF(v),'\n',CRLF);
         end;
        v := '';
        if section='desc' then
          with ati[n] do
            desc:=desc+ UnUTF(line)+CRLF;
        end;
      with ati[n] do
        desc:=trimright(desc);

  end;
 begin
//     line := trim(chopline(s));
//    if (line='&RQ theme file version 1')
//       or (line='R&Q theme file version 1') then
     begin
      InternalprocessTheme(langList);
     end
  end;
const
//   langsFiles : array[0..1] of string = ('RnQ*.utflng', 'RnQ*.lng');
   langsFiles2: array[0..1] of string = ('*.utflng', '*.lng');
   ZipLangs: array[0..0] of string = ('.zlng');
var
  sr: TSearchRec;
  I, e: Integer;
//  str: TStringStream;
//  str2: TMemoryStream;
  ts: TThemeSourcePath;
  fn, FullFN: String;
  //subFile,
  sA: RawByteString;
  w: String;
//  lang_paths : array[0..1] of string;
  lang_paths: array of string;
  lang_subpaths: array of string;
  ti: Integer;
begin
  setLength(lang_paths, 2);
  setLength(lang_subpaths, 2);
  lang_paths[0] := appPath;
  lang_paths[1] := appPath + 'Langs' + PathDelim;
  lang_subpaths[0] := '';
  lang_subpaths[1] := 'Langs' + PathDelim;
  if mainPath > '' then
    begin
      setLength(lang_paths, 3);
      lang_paths[2] := mainPath;
      setLength(lang_subpaths, 3);
      lang_subpaths[2] := ExtractRelativePath(appPath, mainPath);
    end;
//  theme_paths[1] := myPath; // For *.rtz
//  n:=0;
  ClearLangList;
 for ti := Low(lang_paths) to High(lang_paths) do
  for e := 0 to Length(langsFiles2) - 1 do
  begin
    if findFirst(lang_paths[ti] + pLangFileMask + langsFiles2[e], faAnyFile, sr) = 0 then
      repeat
      if sr.name[1]<>'.' then
        begin
        fn:=sr.name;
        if pOnlyFileNames then
          sA := ''
         else
          sA := loadFileA(lang_paths[ti]+fn);
        processFile(lang_subpaths[ti] + fn, '', sA, e=0);
        end;
      until findNext(sr) <> 0;
     findClose(sr);
  end;
 {$IFDEF USE_ZIP}
// for ti := Low(lang_paths) to High(lang_paths) do
   for e := 0 to Length(ZipLangs) - 1 do
   begin
    if findFirst(lang_paths[0]+'*'+ZipLangs[e], faAnyFile, sr) = 0 then
    repeat
    if sr.name[1]<>'.' then
      begin
        fn:=sr.name;
        FullFN := lang_paths[0] + fn;
        ts.zp := TZipFile.Create;
        ts.zp.LoadFromFile(FullFN, pOnlyFileNames);
        if ts.zp.Count > 0 then
         begin
          for I := 0 to ts.zp.Count - 1 do
          begin
           w := ts.zp.Name[i];
           if (  LastDelimiter('\/:', w) <= 0)and
              (MatchesMask(w, pLangFileMask + langsFiles2[0])
               or MatchesMask(w, pLangFileMask + langsFiles2[1])
               )  then
             begin
              if pOnlyFileNames then
                sA := ''
               else
                sA := ts.zp.Data[i];
              processFile(fn, w, sA, MatchesMask(w, pLangFileMask + langsFiles2[0]));
              sA := '';
             end;
          end;
          ts.zp.Free;
         end;
      end;
    until findNext(sr) <> 0;
    findClose(sr);
   end;
 {$ENDIF USE_ZIP}
end; // refreshLangList

procedure ClearLangList;
  procedure Clear1LangList(var tl: aLangInfo);
  var
   t: ToLangInfo;
//   i: Integer;
  begin
 {$IFDEF DELPHI9_UP}
   for t in tl do begin
 {$ELSE DELPHI9_dn}
   for i := Low(tl) to High(tl) do begin
    t := tl[i];
 {$ENDIF DELPHI9_UP}
    begin
     SetLength(t.fn, 0);
     SetLength(t.subFile, 0);
     SetLength(t.desc, 0);
     t.Free;
    end;
   end;
   SetLength(tl, 0);
  end;
begin
 Clear1LangList(langList);
end;


procedure LoadSomeLanguage(pLangFileMask: String; appPath: String; mainPath: String = '');
var
  i: Integer;
  lv: ToLangInfo;
begin
  if gLangFile = c_Int_Lang_FN then
    Exit;

  if gLangFile > '' then
   begin
     lv := ToLangInfo.Create;
     lv.fn := gLangFile;
     lv.subFile := gLangSubFile;

     LangVar := TRnQLang.Create;
     LangVar.loadLanguage2(lv);
     lv.Free;
     if useLang then
       Exit
      else
       FreeAndNil(LangVar);
   end;

  refreshLangList(pLangFileMask, True, appPath, mainPath);
  if Length(langList) = 0 then
    begin
     useLang := false;
//     Exit;
    end
  else
  if Length(langList) = 1 then
    begin
     LangVar := TRnQLang.Create;
     LangVar.loadLanguage2(langList[0]);
//     langList[0]
    end
  else
 {$IFDEF RNQ}
   begin
    refreshLangList(pLangFileMask, False, appPath, mainPath);
    i := showLangsFrm(langList);
    if i < 0 then
      begin
       useLang := false;
       if i=-5 then
         gLangFile := c_Int_Lang_FN;
//       Exit;
      end
     else
      begin
       gLangFile := langList[i].fn;
       gLangSubFile := langList[i].subFile;
       LangVar := TRnQLang.Create;
//       LangVar.loadLanguage;
       LangVar.loadLanguage2(langList[i]);
      end;
   end;
{$ELSE RNQ}
      begin
       i := 0;
       gLangFile := langList[i].fn;
       gLangSubFile := langList[i].subFile;
       LangVar := TRnQLang.Create;
//       LangVar.loadLanguage;
       LangVar.loadLanguage2(langList[i]);
      end;
{$ENDIF RNQ}
  ClearLanglist;
end;

procedure ClearLanguage;
begin
 useLang := false;
 if Assigned(LangVar) then
   begin
     LangVar.ClearLanguage;
     FreeAndNil(LangVar);
   end;
end;


{ TMethodHook }

constructor TMethodHook.Create(pOldProc, pNewProc: pointer);
var
  iOffset : integer;
  iMemProtect : cardinal;
  i : integer;
begin
  Self.pOldProc := pOldProc;
  Self.pNewProc := pNewProc;

  pPosition := pOldProc;
  iOffset := integer( pNewProc ) - integer( pointer( pPosition ) ) - 5;

  for i := 0 to 4 do aOriginal[ i ] := pPosition^[ i ];

  VirtualProtect( pointer( pPosition ), 5, PAGE_EXECUTE_READWRITE,
    @iMemProtect );

  pPosition^[ 0 ] := $E9;
  pPosition^[ 1 ] := byte( iOffset );
  pPosition^[ 2 ] := byte( iOffset shr 8 );
  pPosition^[ 3 ] := byte( iOffset shr 16 );
  pPosition^[ 4 ] := byte( iOffset shr 24 );
end;

destructor TMethodHook.Destroy;
var
  i : integer;
begin
  for i := 0 to 4 do pPosition^[ i ] := aOriginal[ i ];
  inherited;
end;

end.
