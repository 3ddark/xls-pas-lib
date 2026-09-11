# xls-pas-lib

Modernized ZEXMLSS library for Delphi 10.4 Sydney and above.

## Changes from original ZEXMLSS

### zexml.inc
- All legacy ZIP backend defines removed (KAZip, JCL7Z, Abbrevia, SciZip, Synzip)
- `{$DEFINE SYSTEMZIP}` — uses System.Zip (Delphi built-in)
- FPC/Lazarus support dropped (use original ZEXMLSS for that)
- Minimum compiler version enforced: Delphi 10.4 (CompilerVersion >= 34.0)

### compver.inc
- All legacy Delphi version blocks removed (Delphi 1–XE2, C++Builder 1–4)
- Clean named defines: `DELPHI_104_UP`, `DELPHI_11_UP`, `DELPHI_12_UP`
- `DELPHI_UNICODE`, `USE_DEPRECATED_STRING`, `FPC_OR_DELPHI_UNICODE` always set

### zeZipper.pas
- **988 lines → 362 lines** (63% reduction)
- Single ZIP backend: `System.Zip` (no external dependencies)
- All `{$ifdef KAZIP/JCL7Z/ABZIP/SCIZIP/SYNZIP}` blocks removed
- Clean `TZipper` / `TUnZipper` API preserved for compatibility

## Requirements
- Delphi 10.4 Sydney or above
- No external components or DLLs required

## Original project
Based on ZEXMLSS by Ruslan V. Neborak (Avemey)
https://github.com/Avemey/zexmlss