REMM メソッド定義やメソッド呼び出しの()をいい感じに
rubocop -a --only Style/DefWithParentheses,\
Style/MethodCallParentheses,\
Style/MethodDefParentheses

REM インデント崩れを修正
rubocop -a --only Style/IndentationConsistency,\
Style/IndentationWidth,\
Style/MultilineOperationIndentation

REM 空行をいい感じに
rubocop -a --only Style/EmptyLineBetweenDefs,\
Style/EmptyLines,\
Style/EmptyLinesAroundAccessModifier,\
Style/EmptyLinesAroundBlockBody,\
Style/EmptyLinesAroundClassBody,\
Style/EmptyLinesAroundMethodBody,\
Style/EmptyLinesAroundModuleBody,\
Style/TrailingBlankLines

REM コロンやカンマの前後のスペースをいい感じにする
rubocop -a --only Style/SpaceAfterColon,\
Style/SpaceAfterComma,\
Style/SpaceAfterNot,\
Style/SpaceAfterSemicolon,\
Style/SpaceAroundEqualsInParameterDefault,\
Style/SpaceBeforeSemicolon

REM 行末のスペース削除
rubocop -a --only Style/TrailingWhitespace