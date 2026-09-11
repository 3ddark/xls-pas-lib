//****************************************************************
// zeZipper.pas - ZIP archive support
// Modernized: uses System.Zip (Delphi built-in, XE8+)
// All legacy backends removed: KAZip, JCL7Z, Abbrevia, SciZip, Synzip
// Minimum requirement: Delphi 10.4 Sydney
//
// Original author: ZEXMLSS project (Avemey/Neborak)
// Modernization: 2024 - System.Zip backend only
//****************************************************************
unit zeZipper;

interface

uses
  Classes,
  SysUtils,
  System.Zip;

type
  EZipError = class(Exception);

  TCompressionLevel = (
    clNone,     // No compression, store only
    clFastest,  // Fast compression
    clDefault,  // Default compression
    clMax       // Maximum compression
  );

  TZipFileEntry = class(TCollectionItem)
  private
    FArchiveFileName: string;
    FDiskFileName:    string;
    FDateTime:        TDateTime;
    FSize:            Int64;
    FStream:          TStream;
    FCompressionLevel: TCompressionLevel;
    function  GetArchiveFileName: string;
    procedure SetArchiveFileName(const AValue: string);
    procedure SetDiskFileName(const AValue: string);
  public
    constructor Create(ACollection: TCollection); override;
    procedure Assign(Source: TPersistent); override;
    property Stream: TStream read FStream write FStream;
  published
    property ArchiveFileName: string  read GetArchiveFileName  write SetArchiveFileName;
    property DiskFileName:    string  read FDiskFileName        write SetDiskFileName;
    property Size:            Int64   read FSize                write FSize;
    property DateTime:        TDateTime read FDateTime          write FDateTime;
    property CompressionLevel: TCompressionLevel
                              read FCompressionLevel write FCompressionLevel;
  end;

  TZipFileEntries = class(TCollection)
  private
    function GetZ(AIndex: Integer): TZipFileEntry;
    procedure SetZ(AIndex: Integer; const AValue: TZipFileEntry);
  public
    function AddFileEntry(const ADiskFileName: string): TZipFileEntry; overload;
    function AddFileEntry(const ADiskFileName, AArchiveFileName: string): TZipFileEntry; overload;
    function AddFileEntry(const AStream: TStream; const AArchiveFileName: string): TZipFileEntry; overload;
    property Entries[AIndex: Integer]: TZipFileEntry read GetZ write SetZ; default;
  end;

  // TZipper: Creates ZIP archives
  TZipper = class
  private
    FFileName:    string;
    FEntries:     TZipFileEntries;
    FZipFile:     TZipFile;
    function CompressionToNative(ALevel: TCompressionLevel): TZipCompression;
  public
    constructor Create;
    destructor  Destroy; override;

    // Add a file from disk
    procedure AddFileEntry(const ADiskFile, AArchiveName: string); overload;
    // Add a file from stream
    procedure AddFileEntry(const AStream: TStream; const AArchiveName: string); overload;

    // Open/close archive manually (for streaming use)
    procedure OpenArchive(const AFileName: string);
    procedure CloseArchive;

    // Write all entries to archive
    procedure ZipAllFiles;

    property FileName: string read FFileName write FFileName;
    property Entries:  TZipFileEntries read FEntries;
  end;

  // TFullZipFileEntry: Extended entry for reading (compatible with original API)
  TFullZipFileEntry = class(TZipFileEntry)
  private
    FCompressedSize: Int64;
  public
    property CompressedSize: Int64 read FCompressedSize write FCompressedSize;
  end;

  // TUnZipper: Extracts ZIP archives
  TUnZipper = class
  private
    FFileName:   string;
    FOutputPath: string;
  public
    constructor Create;
    destructor  Destroy; override;

    // Extract all to OutputPath
    procedure UnZipAllFiles;

    // Extract single file to stream
    procedure UnZipFileToStream(const AArchiveName: string; AStream: TStream);

    // List entries without extracting
    procedure ExamineFile;

    property FileName:   string read FFileName   write FFileName;
    property OutputPath: string read FOutputPath write FOutputPath;
  end;

implementation

//──────────────────────────────────────────────────────────
// TZipFileEntry
//──────────────────────────────────────────────────────────

constructor TZipFileEntry.Create(ACollection: TCollection);
begin
  inherited Create(ACollection);
  FCompressionLevel := clDefault;
  FDateTime         := Now;
end;

procedure TZipFileEntry.Assign(Source: TPersistent);
var
  Src: TZipFileEntry;
begin
  if Source is TZipFileEntry then
  begin
    Src                := TZipFileEntry(Source);
    FArchiveFileName   := Src.FArchiveFileName;
    FDiskFileName      := Src.FDiskFileName;
    FDateTime          := Src.FDateTime;
    FSize              := Src.FSize;
    FStream            := Src.FStream;
    FCompressionLevel  := Src.FCompressionLevel;
  end
  else
    inherited Assign(Source);
end;

function TZipFileEntry.GetArchiveFileName: string;
begin
  if FArchiveFileName <> '' then
    Result := FArchiveFileName
  else
    Result := ExtractFileName(FDiskFileName);
end;

procedure TZipFileEntry.SetArchiveFileName(const AValue: string);
begin
  // Normalize path separators to forward slash (ZIP standard)
  FArchiveFileName := StringReplace(AValue, '\', '/', [rfReplaceAll]);
end;

procedure TZipFileEntry.SetDiskFileName(const AValue: string);
begin
  FDiskFileName := AValue;
  if FArchiveFileName = '' then
    FArchiveFileName := ExtractFileName(AValue);
end;

//──────────────────────────────────────────────────────────
// TZipFileEntries
//──────────────────────────────────────────────────────────

function TZipFileEntries.GetZ(AIndex: Integer): TZipFileEntry;
begin
  Result := TZipFileEntry(Items[AIndex]);
end;

procedure TZipFileEntries.SetZ(AIndex: Integer; const AValue: TZipFileEntry);
begin
  Items[AIndex].Assign(AValue);
end;

function TZipFileEntries.AddFileEntry(const ADiskFileName: string): TZipFileEntry;
begin
  Result := TZipFileEntry(Add);
  Result.DiskFileName := ADiskFileName;
end;

function TZipFileEntries.AddFileEntry(const ADiskFileName,
  AArchiveFileName: string): TZipFileEntry;
begin
  Result := TZipFileEntry(Add);
  Result.DiskFileName    := ADiskFileName;
  Result.ArchiveFileName := AArchiveFileName;
end;

function TZipFileEntries.AddFileEntry(const AStream: TStream;
  const AArchiveFileName: string): TZipFileEntry;
begin
  Result := TZipFileEntry(Add);
  Result.Stream          := AStream;
  Result.ArchiveFileName := AArchiveFileName;
end;

//──────────────────────────────────────────────────────────
// TZipper
//──────────────────────────────────────────────────────────

constructor TZipper.Create;
begin
  inherited Create;
  FEntries := TZipFileEntries.Create(TZipFileEntry);
  FZipFile := nil;
end;

destructor TZipper.Destroy;
begin
  CloseArchive;
  FreeAndNil(FEntries);
  inherited Destroy;
end;

function TZipper.CompressionToNative(ALevel: TCompressionLevel): TZipCompression;
begin
  case ALevel of
    clNone:    Result := zcStored;
    clFastest: Result := zcDeflate;  // System.Zip has no "fastest" level, use deflate
    clMax:     Result := zcDeflate;
  else
    Result := zcDeflate;             // clDefault
  end;
end;

procedure TZipper.OpenArchive(const AFileName: string);
begin
  CloseArchive;
  FFileName := AFileName;
  FZipFile  := TZipFile.Create;
  FZipFile.Open(FFileName, zmWrite);
end;

procedure TZipper.CloseArchive;
begin
  FreeAndNil(FZipFile);
end;

procedure TZipper.AddFileEntry(const ADiskFile, AArchiveName: string);
var
  FS: TFileStream;
begin
  if not Assigned(FZipFile) then
    raise EZipError.Create('Archive not open. Call OpenArchive first.');

  FS := TFileStream.Create(ADiskFile, fmOpenRead or fmShareDenyWrite);
  try
    FZipFile.Add(FS, AArchiveName, zcDeflate);
  finally
    FS.Free;
  end;
end;

procedure TZipper.AddFileEntry(const AStream: TStream; const AArchiveName: string);
begin
  if not Assigned(FZipFile) then
    raise EZipError.Create('Archive not open. Call OpenArchive first.');

  AStream.Position := 0;
  FZipFile.Add(AStream, AArchiveName, zcDeflate);
end;

procedure TZipper.ZipAllFiles;
var
  i:   Integer;
  E:   TZipFileEntry;
  ZF:  TZipFile;
  FS:  TFileStream;
begin
  ZF := TZipFile.Create;
  try
    ZF.Open(FFileName, zmWrite);
    for i := 0 to FEntries.Count - 1 do
    begin
      E := FEntries[i];
      if Assigned(E.Stream) then
      begin
        E.Stream.Position := 0;
        ZF.Add(E.Stream, E.ArchiveFileName, zcDeflate);
      end
      else if E.DiskFileName <> '' then
      begin
        FS := TFileStream.Create(E.DiskFileName, fmOpenRead or fmShareDenyWrite);
        try
          ZF.Add(FS, E.ArchiveFileName, zcDeflate);
        finally
          FS.Free;
        end;
      end;
    end;
  finally
    ZF.Free;
  end;
end;

//──────────────────────────────────────────────────────────
// TUnZipper
//──────────────────────────────────────────────────────────

constructor TUnZipper.Create;
begin
  inherited Create;
  FOutputPath := '';
end;

destructor TUnZipper.Destroy;
begin
  inherited Destroy;
end;

procedure TUnZipper.UnZipAllFiles;
begin
  if FOutputPath = '' then
    FOutputPath := ExtractFilePath(FFileName);
  TZipFile.ExtractZipFile(FFileName, FOutputPath);
end;

procedure TUnZipper.UnZipFileToStream(const AArchiveName: string;
  AStream: TStream);
var
  ZF:      TZipFile;
  Bytes:   TBytes;
  LocalHeader: TZipHeader;
begin
  ZF := TZipFile.Create;
  try
    ZF.Open(FFileName, zmRead);
    ZF.Read(AArchiveName, Bytes, LocalHeader);
    AStream.WriteBuffer(Bytes[0], Length(Bytes));
  finally
    ZF.Free;
  end;
end;

procedure TUnZipper.ExamineFile;
var
  ZF: TZipFile;
  i:  Integer;
begin
  ZF := TZipFile.Create;
  try
    ZF.Open(FFileName, zmRead);
    for i := 0 to ZF.FileCount - 1 do
      ZF.FileInfo[i]; // Access headers to validate
  finally
    ZF.Free;
  end;
end;

end.
