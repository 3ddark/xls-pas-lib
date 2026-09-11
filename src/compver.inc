//****************************************************************
// compver.inc - Compiler version definitions
// Modernized for Delphi 10.4 Sydney and above
// All legacy Delphi (5/6/7/XE/XE2) and C++Builder defines removed.
// All FPC defines removed.
//****************************************************************

// All Delphi 10.4+ versions have full Unicode string support
{$DEFINE DELPHI_UNICODE}

// Deprecated string type aliases are available
{$DEFINE USE_DEPRECATED_STRING}

// Shared define for Unicode-capable compilers
{$DEFINE FPC_OR_DELPHI_UNICODE}

// FormatSettings record is available (Delphi 2010+)
{$DEFINE Z_USE_FORMAT_SETTINGS}

// Named version defines for clarity
// Delphi 10.4 Sydney   = CompilerVersion 34
// Delphi 11  Alexandria = CompilerVersion 35
// Delphi 12  Athens     = CompilerVersion 36

{$IF CompilerVersion >= 34.0}
  {$DEFINE DELPHI_104_UP}
{$IFEND}

{$IF CompilerVersion >= 35.0}
  {$DEFINE DELPHI_11_UP}
{$IFEND}

{$IF CompilerVersion >= 36.0}
  {$DEFINE DELPHI_12_UP}
{$IFEND}
