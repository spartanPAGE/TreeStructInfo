{

    TSInfoUtils.pp                  last modified: 27 June 2016

    Copyright © Jarosław Baran, furious programming 2013 - 2016.
    All rights reserved.
   __________________________________________________________________________

    This unit is a part of the TreeStructInfo library.

    Includes a set of functions for two-way data conversion (type to string
    and vice versa) of all types supported by TreeStructInfo files. Also
    contains a common procedures and functions needed for correct handling
    of TreeStructInfo files.
   __________________________________________________________________________

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published
    by the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with this program. If not, see <http://www.gnu.org/licenses/>.
   __________________________________________________________________________

}


unit TSInfoUtils;

{$MODE OBJFPC}{$LONGSTRINGS ON}{$HINTS ON}


interface

uses
  TSInfoConsts, TSInfoTypes, LazUTF8, SysUtils, DateUtils, Classes, Math, Types;


{ ----- common procedures & functions ----------------------------------------------------------------------------- }


  procedure ThrowException(const AMessage: String); overload;
  procedure ThrowException(const AMessage: String; const AArgs: array of const); overload;

  function Comment(const ADeclaration, ADefinition: String): TComment;
  function RemoveWhitespaceChars(const AValue: String): String;

  function ReplaceSubStrings(const AValue, AOldPattern, ANewPattern: String): String;
  function GlueStrings(const AMask: String; const AStrings: array of String): String;

  procedure MoveString(const ASource; out ADest: String; ALength: Integer);

  function ValidIdentifier(const AIdentifier: String): Boolean;
  function SameIdentifiers(const AFirst, ASecond: String): Boolean;

  function IncludeTrailingIdentsDelimiter(const APath: String): String;
  function ExcludeTrailingIdentsDelimiter(const APath: String): String;

  function ExtractPathComponent(const AAttrName: String; AComponent: TPathComponent): String;
  procedure ExtractValueComponents(const AValue: String; out AComponents: TValueComponents; out ACount: Integer);

  function IsCurrentNodePath(const APath: String): Boolean;
  function PathWithoutLastNodeName(const APath: String): String;


{ ----- class for data convertion --------------------------------------------------------------------------------- }


type
  TTSInfoDataConverter = class(TObject)
  public
    class function BooleanToValue(ABoolean: Boolean; AFormat: TFormatBoolean): String;
    class function ValueToBoolean(const AValue: String; ADefault: Boolean): Boolean;
  public
    class function IntegerToValue(AInteger: Integer; AFormat: TFormatInteger): String;
    class function ValueToInteger(const AValue: String; ADefault: Integer): Integer;
  public
    class function FloatToValue(AFloat: Double; AFormat: TFormatFloat; ASettings: TFormatSettings): String;
    class function ValueToFloat(const AValue: String; ASettings: TFormatSettings; ADefault: Double): Double;
  public
    class function CurrencyToValue(ACurrency: Currency; AFormat: TFormatCurrency; ASettings: TFormatSettings): String;
    class function ValueToCurrency(const AValue: String; ASettings: TFormatSettings; ADefault: Currency): Currency;
  public
    class function StringToValue(const AString: String; AFormat: TFormatString): String;
    class function ValueToString(const AValue: String; AFormat: TFormatString): String;
  public
    class function DateTimeToValue(const AMask: String; ADateTime: TDateTime; ASettings: TFormatSettings): String;
    class function ValueToDateTime(const AMask, AValue: String; ASettings: TFormatSettings; ADefault: TDateTime): TDateTime;
  public
    class function PointToValue(APoint: TPoint; AFormat: TFormatPoint): String;
    class function ValueToPoint(const AValue: String; ADefault: TPoint): TPoint;
  public
    class procedure ListToValue(AList: TStrings; out AValue: String);
    class procedure ValueToList(const AValue: String; AList: TStrings);
  public
    class procedure BufferToValue(const ABuffer; ASize: Integer; out AValue: String; AFormat: TFormatBuffer);
    class procedure ValueToBuffer(const AValue: String; var ABuffer; ASize, AOffset: Integer);
  end;


{ ----- end interface --------------------------------------------------------------------------------------------- }


implementation


{ ----- common procedures & functions ----------------------------------------------------------------------------- }


procedure ThrowException(const AMessage: String); overload;
begin
  raise ETSInfoFileException.Create(AMessage);
end;


procedure ThrowException(const AMessage: String; const AArgs: array of const);
begin
  raise ETSInfoFileException.CreateFmt(AMessage, AArgs);
end;


function Comment(const ADeclaration, ADefinition: String): TComment;
begin
  Result[ctDeclaration] := ADeclaration;
  Result[ctDefinition] := ADefinition;
end;


function RemoveWhitespaceChars(const AValue: String): String;
var
  intValueLen: Integer;
  pchrLeft, pchrRight: PChar;
begin
  Result := '';
  intValueLen := Length(AValue);

  if intValueLen > 0 then
  begin
    pchrLeft := @AValue[1];
    pchrRight := @AValue[intValueLen];

    while (pchrLeft <= pchrRight) and (pchrLeft^ in WHITESPACE_CHARS) do
      Inc(pchrLeft);

    while (pchrRight > pchrLeft) and (pchrRight^ in WHITESPACE_CHARS) do
      Dec(pchrRight);

    MoveString(pchrLeft^, Result, pchrRight - pchrLeft + 1);
  end;
end;


function ReplaceSubStrings(const AValue, AOldPattern, ANewPattern: String): String;
var
  intValueLen, intOldPtrnLen, intNewPtrnLen, intPlainLen, intResultLen, intResultIdx: Integer;
  pchrPlainBegin, pchrPlainEnd, pchrLast, pchrResult: PChar;
begin
  intValueLen := Length(AValue);

  if intValueLen = 0 then Exit('');
  if AOldPattern = '' then Exit(AValue);

  SetLength(Result, 0);

  intOldPtrnLen := Length(AOldPattern);
  intNewPtrnLen := Length(ANewPattern);
  intResultLen := 0;

  pchrPlainBegin := @AValue[1];
  pchrPlainEnd := pchrPlainBegin;
  pchrLast := @AValue[intValueLen - intOldPtrnLen + 1];

  while pchrPlainEnd <= pchrLast do
    if (pchrPlainEnd^ = AOldPattern[1]) and (CompareByte(pchrPlainEnd^, AOldPattern[1], intOldPtrnLen) = 0) then
    begin
      intPlainLen := pchrPlainEnd - pchrPlainBegin;
      intResultIdx := intResultLen + 1;
      Inc(intResultLen, intPlainLen + intNewPtrnLen);

      SetLength(Result, intResultLen);
      pchrResult := @Result[intResultIdx];
      Move(pchrPlainBegin^, pchrResult^, intPlainLen);

      Inc(pchrResult, intPlainLen);
      Move(ANewPattern[1], pchrResult^, intNewPtrnLen);
      Inc(pchrResult, intNewPtrnLen);

      Inc(pchrPlainEnd, intOldPtrnLen);
      pchrPlainBegin := pchrPlainEnd;
    end
    else
      Inc(pchrPlainEnd);

  if pchrPlainBegin <= pchrPlainEnd then
    Result += String(pchrPlainBegin);
end;


function GlueStrings(const AMask: String; const AStrings: array of String): String;
const
  MASK_FORMAT_CHAR = '%';
var
  pchrToken, pchrLast: PChar;
  intStringIdx: Integer = 0;
  intResultLen: Integer = 0;
  intStringLen: Integer;
begin
  pchrToken := @AMask[1];
  pchrLast := @AMask[Length(AMask)];

  while pchrToken <= pchrLast do
  begin
    if pchrToken^ = MASK_FORMAT_CHAR then
    begin
      intStringLen := Length(AStrings[intStringIdx]);
      SetLength(Result, intResultLen + intStringLen);
      Move(AStrings[intStringIdx][1], Result[intResultLen + 1], intStringLen);

      Inc(intResultLen, intStringLen);
      Inc(intStringIdx);
    end
    else
    begin
      Result += INDENT_CHAR;
      Inc(intResultLen);
    end;

    Inc(pchrToken);
  end;
end;


procedure MoveString(const ASource; out ADest: String; ALength: Integer);
begin
  SetLength(ADest, ALength);
  Move(ASource, ADest[1], ALength);
end;


function ValidIdentifier(const AIdentifier: String): Boolean;
var
  intIdentLen: Integer;
  pchrToken, pchrLast: PChar;
begin
  Result := False;
  intIdentLen := Length(AIdentifier);

  if intIdentLen = 0 then
    ThrowException(EM_EMPTY_IDENTIFIER)
  else
  begin
    pchrToken := @AIdentifier[1];
    pchrLast := @AIdentifier[intIdentLen];

    while pchrToken <= pchrLast do
      if pchrToken^ in INVALID_IDENT_CHARS then
        ThrowException(EM_INCORRECT_IDENTIFIER_CHARACTER, [pchrToken^, Ord(pchrToken^)])
      else
        Inc(pchrToken);

    Result := True;
  end;
end;


function SameIdentifiers(const AFirst, ASecond: String): Boolean;
var
  intFirstLen, intSecondLen: Integer;
begin
  intFirstLen := Length(AFirst);
  intSecondLen := Length(ASecond);

  Result := (intFirstLen > 0) and (intFirstLen = intSecondLen) and
            (CompareByte(AFirst[1], ASecond[1], intFirstLen) = 0);
end;


function IncludeTrailingIdentsDelimiter(const APath: String): String;
var
  intPathLen: Integer;
begin
  intPathLen := Length(APath);

  if (intPathLen > 0) and (APath[intPathLen] <> IDENTS_DELIMITER) then
    Result := APath + IDENTS_DELIMITER
  else
    Result := APath;
end;


function ExcludeTrailingIdentsDelimiter(const APath: String): String;
var
  intPathLen: Integer;
begin
  intPathLen := Length(APath);

  if (intPathLen > 0) and (APath[intPathLen] = IDENTS_DELIMITER) then
  begin
    SetLength(Result, intPathLen - 1);
    Move(APath[1], Result[1], intPathLen - 1);
  end
  else
    Result := APath;
end;


function ExtractPathComponent(const AAttrName: String; AComponent: TPathComponent): String;
var
  intValueLen: Integer;
  pchrFirst, pchrToken, pchrLast: PChar;
begin
  Result := '';
  intValueLen := Length(AAttrName);

  if intValueLen > 0 then
  begin
    pchrFirst := @AAttrName[1];
    pchrLast := @AAttrName[intValueLen];
    pchrToken := pchrLast;

    while (pchrToken > pchrFirst) and (pchrToken^ <> IDENTS_DELIMITER) do
      Dec(pchrToken);

    case AComponent of
      pcAttributeName:
        if pchrToken^ = IDENTS_DELIMITER then
          MoveString(PChar(pchrToken + 1)^, Result, pchrLast - pchrToken)
        else
          Result := AAttrName;
      pcAttributePath:
        if pchrToken^ = IDENTS_DELIMITER then
          MoveString(pchrFirst^, Result, pchrToken - pchrFirst + 1);
    end;
  end;
end;


procedure ExtractValueComponents(const AValue: String; out AComponents: TValueComponents; out ACount: Integer);
var
  pchrBegin, pchrToken, pchrLast: PChar;
  strValue: String;
begin
  ACount := 0;
  SetLength(AComponents, 0);

  if AValue <> '' then
    if AValue = ONE_BLANK_VALUE_LINE_CHAR then
    begin
      SetLength(AComponents, 1);
      AComponents[0] := ONE_BLANK_VALUE_LINE_CHAR;
      ACount := 1;
    end
    else
    begin
      strValue := AValue + VALUES_DELIMITER;

      pchrBegin := @strValue[1];
      pchrToken := pchrBegin;
      pchrLast := @strValue[Length(strValue)];

      while pchrToken <= pchrLast do
        if pchrToken^ = VALUES_DELIMITER then
        begin
          SetLength(AComponents, ACount + 1);
          MoveString(pchrBegin^, AComponents[ACount], pchrToken - pchrBegin);
          Inc(ACount);

          Inc(pchrToken);
          pchrBegin := pchrToken;
        end
        else
          Inc(pchrToken);
    end;
end;


function IsCurrentNodePath(const APath: String): Boolean;
begin
  Result := (APath = '') or (APath = CURRENT_NODE_SYMBOL);
end;


function PathWithoutLastNodeName(const APath: String): String;
var
  pchrFirst, pchrToken: PChar;
begin
  Result := '';

  if APath <> '' then
  begin
    pchrFirst := @APath[1];
    pchrToken := @APath[Length(APath) - 2];

    while (pchrToken >= pchrFirst) and (pchrToken^ <> IDENTS_DELIMITER) do
      Dec(pchrToken);

    if pchrToken > pchrFirst then
      MoveString(pchrFirst^, Result, pchrToken - pchrFirst + 1);
  end;
end;


{ ----- TTSInfoDataConverter class -------------------------------------------------------------------------------- }


{ ----- boolean convertions ------------------------------- }


class function TTSInfoDataConverter.BooleanToValue(ABoolean: Boolean; AFormat: TFormatBoolean): String;
begin
  Result := BOOLEAN_VALUES[ABoolean, AFormat];
end;


class function TTSInfoDataConverter.ValueToBoolean(const AValue: String; ADefault: Boolean): Boolean;
var
  pchrToken, pchrLast: PChar;
  fbToken: TFormatBoolean;
begin
  Result := ADefault;

  if AValue <> '' then
  begin
    pchrToken := @AValue[1];
    pchrLast := @AValue[Length(AValue)];

    if pchrToken^ in SMALL_LETTERS then
      Dec(pchrToken^, 32);

    Inc(pchrToken);

    while pchrToken <= pchrLast do
    begin
      if pchrToken^ in CAPITAL_LETTERS then
        Inc(pchrToken^, 32);

      Inc(pchrToken);
    end;

    for fbToken in TFormatBoolean do
      if SameIdentifiers(AValue, BOOLEAN_VALUES[True, fbToken]) then
        Exit(True)
      else
        if SameIdentifiers(AValue, BOOLEAN_VALUES[False, fbToken]) then
          Exit(False);
  end;
end;


{ ----- integer conversions ------------------------------- }


class function TTSInfoDataConverter.IntegerToValue(AInteger: Integer; AFormat: TFormatInteger): String;
var
  boolIsNegative: Boolean;
  strRawValue: String;
  intRawValueLen, intRawValueMinLen: Integer;
  pchrNonZeroDigit, pchrLast: PChar;
begin
  if AFormat in [fiUnsignedDecimal, fiSignedDecimal] then
  begin
    Str(AInteger, Result);

    if (AFormat = fiSignedDecimal) and (AInteger > 0) then
      Result := '+' + Result;
  end
  else
  begin
    boolIsNegative := AInteger < 0;
    AInteger := Abs(AInteger);

    case AFormat of
      fiHexadecimal: strRawValue := HexStr(AInteger, SizeOf(Integer) * 2);
      fiOctal:       strRawValue := OctStr(AInteger, SizeOf(Integer) * 3);
      fiBinary:      strRawValue := BinStr(AInteger, SizeOf(Integer) * 8);
    end;

    intRawValueLen := Length(strRawValue);
    intRawValueMinLen := INTEGER_MIN_LENGTHS[AFormat] - 1;

    pchrNonZeroDigit := @strRawValue[1];
    pchrLast := @strRawValue[intRawValueLen];

    while (pchrNonZeroDigit < pchrLast - intRawValueMinLen) and (pchrNonZeroDigit^ = '0') do
      Inc(pchrNonZeroDigit);

    intRawValueLen := pchrLast - pchrNonZeroDigit + 1;
    SetLength(Result, intRawValueLen + 2 + Ord(boolIsNegative));
    Move(pchrNonZeroDigit^, Result[3 + Ord(boolIsNegative)], intRawValueLen);
    Move(INTEGER_UNIVERSAL_SYSTEM_PREFIXES[AFormat][1], Result[1 + Ord(boolIsNegative)], 2);

    if boolIsNegative then
      Result[1] := '-';
  end;
end;


class function TTSInfoDataConverter.ValueToInteger(const AValue: String; ADefault: Integer): Integer;
var
  pchrToken, pchrLast: PChar;
  strValue: String;
  intValueLen, intCode: Integer;
  boolIsNegative: Boolean = False;
  fiNumericalFormat: TFormatInteger = fiUnsignedDecimal;
begin
  strValue := AValue;
  intValueLen := Length(strValue);

  if intValueLen > 2 then
  begin
    pchrToken := @AValue[1];
    pchrLast := @AValue[intValueLen];

    if pchrToken^ = '-' then
    begin
      boolIsNegative := True;
      Inc(pchrToken);
    end;

    if pchrToken^ = '0' then
    begin
      Inc(pchrToken);

      if pchrToken^ in CAPITAL_LETTERS then
        Inc(pchrToken^, 32);

      if pchrToken^ in NUMERICAL_SYSTEM_CHARS then
      begin
        case pchrToken^ of
          'x': fiNumericalFormat := fiHexadecimal;
          'o': fiNumericalFormat := fiOctal;
          'b': fiNumericalFormat := fiBinary;
        end;

        intValueLen := pchrLast - pchrToken;
        SetLength(strValue, intValueLen + 1);
        Move(PChar(pchrToken + 1)^, strValue[2], intValueLen);
        strValue[1] := INTEGER_PASCAL_SYSTEM_PREFIXES[fiNumericalFormat];
      end;
    end;
  end;

  Val(strValue, Result, intCode);

  if intCode <> 0 then
    Result := ADefault
  else
    if boolIsNegative and (fiNumericalFormat in [fiHexadecimal, fiOctal, fiBinary]) then
      Result := -Result;
end;


{ ----- float conversions --------------------------------- }


class function TTSInfoDataConverter.FloatToValue(AFloat: Double; AFormat: TFormatFloat; ASettings: TFormatSettings): String;
var
  boolMustBeSigned: Boolean;
begin
  boolMustBeSigned := AFormat in [ffSignedGeneral, ffSignedExponent, ffSignedNumber];

  if IsInfinite(AFloat) then
  begin
    if AFloat = Infinity then
    begin
      if boolMustBeSigned then
        Exit(SIGNED_INFINITY_VALUE)
      else
        Exit(UNSIGNED_INFINITY_VALUE);
    end
    else
      Exit(NEGATIVE_INFINITY_VALUE);
  end
  else
    if IsNan(AFloat) then
      Exit(NOT_A_NUMBER_VALUE);

  Result := FloatToStrF(AFloat, FLOAT_FORMATS[AFormat], 15, 10, ASettings);

  if boolMustBeSigned and (CompareValue(AFloat, 0) = GreaterThanValue) then
    Result := '+' + Result;
end;


class function TTSInfoDataConverter.ValueToFloat(const AValue: String; ASettings: TFormatSettings; ADefault: Double): Double;
var
  pchrToken, pchrLast: PChar;
begin
  if not TryStrToFloat(AValue, Result, ASettings) then
  begin
    Result := ADefault;

    if Length(AValue) >= 3 then
    begin
      pchrToken := @AValue[1];
      pchrLast := @AValue[Length(AValue)];

      if pchrToken^ in PLUS_MINUS_CHARS then
        Inc(pchrToken);

      if pchrToken^ in SMALL_LETTERS then
        Dec(pchrToken^, 32);

      Inc(pchrToken);

      while (pchrToken <= pchrLast) do
        if pchrToken^ in CAPITAL_LETTERS then
        begin
          Inc(pchrToken^, 32);
          Inc(pchrToken);
        end
        else
          Break;

      if (CompareStr(AValue, UNSIGNED_INFINITY_VALUE) = 0) or (CompareStr(AValue, SIGNED_INFINITY_VALUE) = 0) then
        Exit(Infinity);

      if CompareStr(AValue, NEGATIVE_INFINITY_VALUE) = 0 then
        Exit(NegInfinity);

      if CompareStr(AValue, NOT_A_NUMBER_VALUE) = 0 then
        Exit(NaN);
    end;
  end;
end;


{ ----- currency converions ------------------------------- }


class function TTSInfoDataConverter.CurrencyToValue(ACurrency: Currency; AFormat: TFormatCurrency; ASettings: TFormatSettings): String;
begin
  case AFormat of
    fcUnsignedPrice, fcSignedPrice:
      Result := CurrToStrF(ACurrency, ffCurrency, 2, ASettings);
    fcUnsignedExchangeRate, fcSignedExchangeRate:
      Result := CurrToStrF(ACurrency, ffCurrency, 4, ASettings);
  end;

  if (AFormat in [fcSignedPrice, fcSignedExchangeRate]) and (ACurrency > 0) then
    Result := '+' + Result;
end;


class function TTSInfoDataConverter.ValueToCurrency(const AValue: String; ASettings: TFormatSettings; ADefault: Currency): Currency;
var
  intValueLen, intCurrStringLen: Integer;
  pchrFirst, pchrToken, pchrLast: PChar;
  strValue: String;
begin
  intValueLen := Length(AValue);

  if intValueLen = 0 then
    Result := ADefault
  else
  begin
    intCurrStringLen := Length(ASettings.CurrencyString);

    if (intCurrStringLen > 0) and (intValueLen > intCurrStringLen) then
    begin
      pchrFirst := @AValue[1];
      pchrLast := @AValue[intValueLen];
      pchrToken := pchrLast - intCurrStringLen + 1;

      MoveString(pchrToken^, strValue, pchrLast - pchrToken + 1);

      if CompareStr(strValue, ASettings.CurrencyString) = 0 then
      begin
        repeat
          Dec(pchrToken);
        until pchrToken^ in NUMBER_CHARS;

        MoveString(pchrFirst^, strValue, pchrToken - pchrFirst + 1);
      end
      else
        strValue := AValue;
    end
    else
      strValue := AValue;

    if not TryStrToCurr(strValue, Result, ASettings) then
      Result := ADefault;
  end;
end;


{ ----- string conversion --------------------------------- }


class function TTSInfoDataConverter.StringToValue(const AString: String; AFormat: TFormatString): String;
begin
  case AFormat of
    fsOriginal:  Result := AString;
    fsLowerCase: Result := UTF8LowerCase(AString);
    fsUpperCase: Result := UTF8UpperCase(AString);
  end;
end;


class function TTSInfoDataConverter.ValueToString(const AValue: String; AFormat: TFormatString): String;
begin
  case AFormat of
    fsOriginal:  Result := AValue;
    fsLowerCase: Result := UTF8LowerCase(AValue);
    fsUpperCase: Result := UTF8UpperCase(AValue);
  end;
end;


{ ----- date & time conversions --------------------------- }


class function TTSInfoDataConverter.DateTimeToValue(const AMask: String; ADateTime: TDateTime; ASettings: TFormatSettings): String;
var
  intMaskLen, intResultLen, intFormatLen: UInt32;
  pchrMaskToken, pchrMaskLast: PChar;
  chrFormat: Char;
  strMask: String;
  strResult: String = '';
  bool12HourClock: Boolean = False;

  procedure IncreaseMaskCharacters();
  begin
    while (pchrMaskToken < pchrMaskLast) do
    begin
      if pchrMaskToken^ in SMALL_LETTERS then
        Dec(pchrMaskToken^, 32)
      else
        if pchrMaskToken^ in DATE_TIME_PLAIN_TEXT_CHARS then
        begin
          chrFormat := pchrMaskToken^;

          repeat
            Inc(pchrMaskToken);
          until (pchrMaskToken = pchrMaskLast) or (pchrMaskToken^ = chrFormat);
        end;

      Inc(pchrMaskToken);
    end;

    pchrMaskToken := @strMask[1];
  end;

  procedure GetClockInfo();
  begin
    while (pchrMaskToken < pchrMaskLast) do
      if pchrMaskToken^ = 'A' then
      begin
        bool12HourClock := True;
        Break;
      end
      else
        Inc(pchrMaskToken);

    pchrMaskToken := @strMask[1];
  end;

  procedure SaveString(const AString: String);
  var
    intStringLen: UInt32;
  begin
    intStringLen := Length(AString);
    SetLength(strResult, intResultLen + intStringLen);
    Move(AString[1], strResult[intResultLen + 1], intStringLen);
    Inc(intResultLen, intStringLen);
  end;

  procedure SaveNumber(const ANumber, ADigits: UInt16);
  var
    strNumber: String;
  begin
    Str(ANumber, strNumber);
    strNumber := StringOfChar('0', ADigits - Length(strNumber)) + strNumber;
    SaveString(strNumber);
  end;

  procedure GetFormatInfo();
  begin
    chrFormat := pchrMaskToken^;
    intFormatLen := 0;

    repeat
      Inc(intFormatLen);
      Inc(pchrMaskToken);
    until (pchrMaskToken = pchrMaskLast) or (pchrMaskToken^ <> chrFormat);
  end;

var
  intYear, intMonth, intDay, intHour, intMinute, intSecond, intMilliSecond, intDayOfWeek: UInt16;
begin
  intMaskLen := Length(AMask);

  if intMaskLen > 0 then
  begin
    strMask := AMask + #32;
    Inc(intMaskLen);
    intResultLen := 0;
    pchrMaskToken := @strMask[1];
    pchrMaskLast := @strMask[intMaskLen];

    IncreaseMaskCharacters();
    GetClockInfo();

    DecodeDateTime(ADateTime, intYear, intMonth, intDay, intHour, intMinute, intSecond, intMilliSecond);
    intDayOfWeek := DayOfWeek(ADateTime);

    while pchrMaskToken < pchrMaskLast do
    begin
      if pchrMaskToken^ in DATE_TIME_FORMAT_CHARS then
      begin
        GetFormatInfo();

        case chrFormat of
          'Y': case intFormatLen of
                 2: SaveNumber(intYear mod 100, 2);
                 4: SaveNumber(intYear, 4);
               end;
          'M': case intFormatLen of
                 1, 2: SaveNumber(intMonth, intFormatLen);
                 3:    SaveString(ASettings.ShortMonthNames[intMonth]);
                 4:    SaveString(ASettings.LongMonthNames[intMonth]);
               end;
          'D': case intFormatLen of
                 1, 2: SaveNumber(intDay, intFormatLen);
                 3:    SaveString(ASettings.ShortDayNames[intDayOfWeek]);
                 4:    SaveString(ASettings.LongDayNames[intDayOfWeek]);
               end;
          'H': case intFormatLen of
                 1, 2: if bool12HourClock then
                       begin
                         if intHour < 12 then
                         begin
                           if intHour = 0 then
                             SaveNumber(12, intFormatLen)
                           else
                             SaveNumber(intHour, intFormatLen);
                         end
                         else
                           if intHour = 12 then
                             SaveNumber(intHour, intFormatLen)
                           else
                             SaveNumber(intHour - 12, intFormatLen);
                       end
                       else
                         SaveNumber(intHour, intFormatLen);
               end;
          'N': case intFormatLen of
                 1, 2: SaveNumber(intMinute, intFormatLen);
               end;
          'S': case intFormatLen of
                 1, 2: SaveNumber(intSecond, intFormatLen);
               end;
          'Z': case intFormatLen of
                 1, 3: SaveNumber(intMilliSecond, intFormatLen);
               end;
          'A': begin
                 if intHour < 12 then
                   SaveString(ASettings.TimeAMString)
                 else
                   SaveString(ASettings.TimePMString);

                 Inc(pchrMaskToken, 4);
               end;
        end;
      end
      else
        if pchrMaskToken^ in DATE_TIME_SEPARATOR_CHARS then
        begin
          case pchrMaskToken^ of
            '.', '-', '/': SaveString(ASettings.DateSeparator);
            ':':           SaveString(ASettings.TimeSeparator);
          end;

          Inc(pchrMaskToken);
        end
        else
          if pchrMaskToken^ in DATE_TIME_PLAIN_TEXT_CHARS then
          begin
            chrFormat := pchrMaskToken^;
            Inc(pchrMaskToken);

            repeat
              SaveString(pchrMaskToken^);
              Inc(pchrMaskToken);
            until (pchrMaskToken = pchrMaskLast) or (pchrMaskToken^ = chrFormat);

            Inc(pchrMaskToken);
          end
          else
          begin
            SaveString(pchrMaskToken^);
            Inc(pchrMaskToken);
          end;
    end;
  end;

  Result := strResult;
end;


class function TTSInfoDataConverter.ValueToDateTime(const AMask, AValue: String; ASettings: TFormatSettings; ADefault: TDateTime): TDateTime;
var
  intValueLen, intMaskLen: Integer;
  pchrMaskToken, pchrMaskLast: PChar;
  pchrValueBegin, pchrValueEnd, pchrValueLast: PChar;
  strValue, strMask: String;
  chrFormat: Char;

  procedure IncreaseMaskCharacters();
  begin
    while (pchrMaskToken < pchrMaskLast) do
    begin
      if pchrMaskToken^ in SMALL_LETTERS then
        Dec(pchrMaskToken^, 32)
      else
        if pchrMaskToken^ in DATE_TIME_PLAIN_TEXT_CHARS then
        begin
          chrFormat := pchrMaskToken^;

          repeat
            Inc(pchrMaskToken);
          until (pchrMaskToken = pchrMaskLast) or (pchrMaskToken^ = chrFormat);
        end;

      Inc(pchrMaskToken);
    end;

    pchrMaskToken := @strMask[1];
  end;

var
  intYear, intMonth, intDay, intHour, intMinute, intSecond, intMilliSecond: UInt16;

  procedure InitDateTimeComponents();
  begin
    intYear := 1899;
    intMonth := 12;
    intDay := 30;
    intHour := 0;
    intMinute := 0;
    intSecond := 0;
    intMilliSecond := 0;
  end;

var
  chrFormatSep: Char;
  intFormatLen: UInt32 = 0;
  strFormatVal: String = '';

  procedure GetFormatInfo();
  begin
    chrFormat := pchrMaskToken^;

    if chrFormat = 'A' then
      Inc(pchrMaskToken, 5)
    else
    begin
      intFormatLen := 0;

      repeat
        Inc(intFormatLen);
        Inc(pchrMaskToken);
      until (pchrMaskToken = pchrMaskLast) or (pchrMaskToken^ <> chrFormat);
    end;

    if pchrMaskToken^ in DATE_TIME_SEPARATOR_CHARS then
    begin
      case pchrMaskToken^ of
        '.', '-', '/': chrFormatSep := ASettings.DateSeparator;
        ':':           chrFormatSep := ASettings.TimeSeparator;
      end;

      Exit();
    end;

    if pchrMaskToken^ in DATE_TIME_PLAIN_TEXT_CHARS then
      Inc(pchrMaskToken);

    chrFormatSep := pchrMaskToken^;
  end;

  procedure GetFormatValue();
  begin
    while pchrValueEnd^ <> chrFormatSep do
      Inc(pchrValueEnd);

    MoveString(pchrValueBegin^, strFormatVal, pchrValueEnd - pchrValueBegin);
    pchrValueBegin := pchrValueEnd;
  end;

  function StringToNumber(const AString: String): UInt16;
  var
    intCode: Integer;
  begin
    Val(AString, Result, intCode);

    if intCode <> 0 then
      Result := 0;
  end;

  function MonthNameToNumber(const AName: String; const AMonthNames: TMonthNameArray): Integer;
  var
    intNameLen: Integer;
    I: Integer = 1;
  begin
    Result := 1;
    intNameLen := Length(AName);

    while I <= High(AMonthNames) do
      if (intNameLen = Length(AMonthNames[I])) and
         (CompareStr(AName, AMonthNames[I]) = 0) then
      begin
        Result := I + 1;
        Break;
      end
      else
        Inc(I);
  end;

  procedure IncrementMaskAndValueTokens();
  begin
    Inc(pchrMaskToken);
    Inc(pchrValueBegin);
    Inc(pchrValueEnd);
  end;

var
  bool12HourClock: Boolean = False;
  boolIsAMHour: Boolean = False;
  intPivot: UInt16;
begin
  strMask := AMask;
  strValue := AValue;

  if (strMask <> '') and (strValue <> '') then
  begin
    InitDateTimeComponents();

    strMask += #32;
    strValue += #32;
    intMaskLen := Length(strMask);
    intValueLen := Length(strValue);

    pchrMaskToken := @strMask[1];
    pchrMaskLast := @strMask[intMaskLen];
    pchrValueBegin := @strValue[1];
    pchrValueEnd := pchrValueBegin;
    pchrValueLast := @strValue[intValueLen];

    IncreaseMaskCharacters();

    while (pchrMaskToken < pchrMaskLast) and (pchrValueEnd < pchrValueLast) do
      if pchrMaskToken^ in DATE_TIME_FORMAT_CHARS then
      begin
        GetFormatInfo();
        GetFormatValue();

        case chrFormat of
          'Y': case intFormatLen of
                 2: begin
                      intYear := StringToNumber(strFormatVal);
                      intPivot := YearOf(Now()) - ASettings.TwoDigitYearCenturyWindow;
                      Inc(intYear, intPivot div 100 * 100);

                      if (ASettings.TwoDigitYearCenturyWindow > 0) and (intYear < intPivot) then
                        Inc(intYear, 100);
                    end;
                 4: intYear := StringToNumber(strFormatVal);
               end;
          'M': case intFormatLen of
                 1, 2: intMonth := StringToNumber(strFormatVal);
                 3:    intMonth := MonthNameToNumber(strFormatVal, ASettings.ShortMonthNames);
                 4:    intMonth := MonthNameToNumber(strFormatVal, ASettings.LongMonthNames);
               end;
          'D': case intFormatLen of
                 1, 2: intDay := StringToNumber(strFormatVal);
               end;
          'H': case intFormatLen of
                 1, 2: intHour := StringToNumber(strFormatVal);
               end;
          'N': case intFormatLen of
                 1, 2: intMinute := StringToNumber(strFormatVal);
               end;
          'S': case intFormatLen of
                 1, 2: intSecond := StringToNumber(strFormatVal);
               end;
          'Z': case intFormatLen of
                 1, 3: intMilliSecond := StringToNumber(strFormatVal);
               end;
          'A': begin
                 bool12HourClock := True;
                 boolIsAMHour := CompareStr(strFormatVal, ASettings.TimeAMString) = 0;
               end;
        end;
      end
      else
        if pchrMaskToken^ in DATE_TIME_PLAIN_TEXT_CHARS then
        begin
          chrFormat := pchrMaskToken^;
          Inc(pchrMaskToken);

          repeat
            IncrementMaskAndValueTokens();
          until (pchrMaskToken = pchrMaskLast) or (pchrMaskToken^ = chrFormat);

          Inc(pchrMaskToken);
        end
        else
          IncrementMaskAndValueTokens();

    if bool12HourClock then
      if boolIsAMHour then
      begin
        if intHour = 12 then
          intHour := 0;
      end
      else
        if intHour < 12 then
          Inc(intHour, 12);

    if not TryEncodeDateTime(intYear, intMonth, intDay, intHour, intMinute, intSecond, intMilliSecond, Result) then
      Result := ADefault;
  end
  else
    Result := ADefault;
end;


{ ----- point conversions --------------------------------- }


class function TTSInfoDataConverter.PointToValue(APoint: TPoint; AFormat: TFormatPoint): String;
var
  strCoordX, strCoordY: String;
begin
  strCoordX := IntegerToValue(APoint.X, POINT_SYSTEMS[AFormat]);
  strCoordY := IntegerToValue(APoint.Y, POINT_SYSTEMS[AFormat]);

  Result := GlueStrings('%%%', [strCoordX, COORDS_DELIMITER, strCoordY]);
end;


class function TTSInfoDataConverter.ValueToPoint(const AValue: String; ADefault: TPoint): TPoint;

  procedure ExtractPointCoord(AFirst, ALast: PChar; out ACoord: String); inline;
  var
    intNegativeOffset: UInt8;
    pchrSystem: PChar;
    fiFormat: TFormatInteger;
  begin
    if ALast - AFirst + 1 >= MIN_NO_DECIMAL_VALUE_LEN then
    begin
      intNegativeOffset := Ord(AFirst^ = '-');
      pchrSystem := AFirst + intNegativeOffset;

      if (pchrSystem^ = '0') and (PChar(pchrSystem + 1)^ in NUMERICAL_SYSTEM_CHARS) then
      begin
        Inc(pchrSystem);

        case pchrSystem^ of
          'x': fiFormat := fiHexadecimal;
          'o': fiFormat := fiOctal;
          'b': fiFormat := fiBinary;
        end;

        SetLength(ACoord, ALast - pchrSystem + 1 + intNegativeOffset);
        Move(pchrSystem^, ACoord[1 + intNegativeOffset], ALast - pchrSystem + 1);
        ACoord[1 + intNegativeOffset] := INTEGER_PASCAL_SYSTEM_PREFIXES[fiFormat];

        if Boolean(intNegativeOffset) then
          ACoord[1] := '-';

        Exit();
      end;
    end;

    MoveString(AFirst^, ACoord, ALast - AFirst + 1);
  end;

var
  pchrFirst, pchrLast, pchrDelimiter: PChar;
  strCoordX, strCoordY: String;
  intValueLen, intCoordXCode, intCoordYCode: Integer;
begin
  intValueLen := Length(AValue);

  if intValueLen >= MIN_POINT_VALUE_LEN then
  begin
    pchrFirst := @AValue[1];
    pchrLast := @AValue[intValueLen];
    pchrDelimiter := pchrFirst + 1;

    while (pchrDelimiter < pchrLast) and (pchrDelimiter^ <> COORDS_DELIMITER) do
      Inc(pchrDelimiter);

    if pchrDelimiter < pchrLast then
    begin
      ExtractPointCoord(pchrFirst, pchrDelimiter - 1, strCoordX);
      ExtractPointCoord(pchrDelimiter + 1, pchrLast, strCoordY);

      Val(strCoordX, Result.X, intCoordXCode);
      Val(strCoordY, Result.Y, intCoordYCode);

      if (intCoordXCode = 0) and (intCoordYCode = 0) then
        Exit();
    end;
  end;

  Result := ADefault;
end;


{ ----- list conversions ---------------------------------- }


class procedure TTSInfoDataConverter.ListToValue(AList: TStrings; out AValue: String);
var
  intLineIdx: Integer;
begin
  if AList.Count = 0 then
    AValue := ''
  else
    if (AList.Count = 1) and (AList[0] = '') then
      AValue := ONE_BLANK_VALUE_LINE_CHAR
    else
    begin
      AValue := AList[0];

      for intLineIdx := 1 to AList.Count - 1 do
        AValue += VALUES_DELIMITER + AList[intLineIdx];
    end;
end;


class procedure TTSInfoDataConverter.ValueToList(const AValue: String; AList: TStrings);
var
  vcList: TValueComponents;
  intLinesCnt, intLineIdx: Integer;
begin
  ExtractValueComponents(AValue, vcList, intLinesCnt);

  AList.BeginUpdate();
  try
    for intLineIdx := 0 to intLinesCnt - 1 do
      AList.Add(vcList[intLineIdx]);
  finally
    AList.EndUpdate();
  end;
end;


{ ----- buffer & stream conversions ----------------------- }


class procedure TTSInfoDataConverter.BufferToValue(const ABuffer; ASize: Integer; out AValue: String; AFormat: TFormatBuffer);
const
  HEX_CHARS: array [0 .. 15] of Char = '0123456789ABCDEF';
var
  bdaBuffer: TByteDynArray;
  intValueLen, intByteIdx: Integer;
  pintByte: PUInt8;
  pchrByte, pchrLast: PChar;
begin
  if ASize <= 0 then Exit();

  SetLength(bdaBuffer, ASize);
  Move(ABuffer, bdaBuffer[0], ASize);

  intValueLen := (ASize * 2) + ((ASize - 1) div UInt8(AFormat));
  SetLength(AValue, intValueLen);

  pintByte := @bdaBuffer[0];
  pchrByte := @AValue[1];
  pchrLast := @AValue[intValueLen];

  while pchrByte < pchrLast do
  begin
    intByteIdx := 0;

    while (intByteIdx < UInt8(AFormat)) and (pchrByte < pchrLast) do
    begin
      PChar(pchrByte + 0)^ := HEX_CHARS[pintByte^ shr 4 and 15];
      PChar(pchrByte + 1)^ := HEX_CHARS[pintByte^ and 15];

      Inc(pintByte);
      Inc(pchrByte, 2);
      Inc(intByteIdx);
    end;

    if pchrByte < pchrLast then
    begin
      pchrByte^ := VALUES_DELIMITER;
      Inc(pchrByte);
    end;
  end;
end;


class procedure TTSInfoDataConverter.ValueToBuffer(const AValue: String; var ABuffer; ASize, AOffset: Integer);
var
  bdaBuffer: TByteDynArray;
  strValue: String;
  intValueLen: Integer;
  pintByte: PUInt8;
  pchrByte, pchrBufferLast, pchrValueLast: PChar;
begin
  if ASize <= 0 then Exit();

  strValue := ReplaceSubStrings(AValue, VALUES_DELIMITER, '');
  intValueLen := Length(strValue);

  if intValueLen > 0 then
  begin
    SetLength(bdaBuffer, ASize);
    FillChar(bdaBuffer[0], ASize, 0);

    pintByte := @bdaBuffer[0];
    pchrByte := @strValue[AOffset * 2 + 1];
    pchrBufferLast := pchrByte + ASize * 2;
    pchrValueLast := @strValue[intValueLen];

    while (pchrByte <= pchrBufferLast) and (pchrByte <= pchrValueLast) do
    begin
      if pchrByte^ in NUMBER_CHARS then
        Dec(pchrByte^, 48)
      else
        if pchrByte^ in HEX_LETTERS then
          Dec(pchrByte^, 55)
        else
          Exit();

      Inc(pchrByte);
    end;

    pchrByte := @strValue[AOffset * 2 + 1];

    while (pchrByte < pchrBufferLast) and (pchrByte < pchrValueLast) do
    begin
      pintByte^ := UInt8(pchrByte^) shl 4 or PUInt8(pchrByte + 1)^;
      Inc(pintByte);
      Inc(pchrByte, 2);
    end;

    Move(bdaBuffer[0], ABuffer, ASize);
  end;
end;


{ ----- end implementation ---------------------------------------------------------------------------------------- }


end.

