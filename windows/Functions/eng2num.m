function number = eng2num( stringValue )
    stringValue = convertStringsToChars( stringValue );
    i = length( stringValue );
    while i > 0 && isnan( str2double( stringValue( 1 : i ) ) )
        i = i - 1;
    end
    firstNumber = stringValue( 1 : i );
    stringValue = stringValue( i + 1 : end );
    j = 0;
    while j < length( stringValue ) && isstrprop( stringValue( j + 1 ), 'alpha' )
        j = j + 1;
    end
    firstLetters = stringValue( 1 : j );
    stringValue = stringValue( j + 1 : end );
    k = 0;
    while k < length( stringValue ) && ~isnan( str2double( stringValue( 1 : k + 1 ) ) )
        k = k + 1;
    end
    secondNumber = stringValue( 1 : k );
    remainder = stringValue( k + 1 : end );
    if isempty( firstNumber )
        number = NaN;
    else
        number = str2double( firstNumber );
    end
    if ~isempty( secondNumber )
        if contains( firstNumber , '.' ) || contains( secondNumber , '.' )
            number = NaN;
            return;
        end
        if number >= 0
            sign = 1;
        else
            sign = - 1;
        end
        number = number + sign * 10 ^ ( - length( secondNumber ) * str2double( secondNumber ) );
    end
    factor = 1;
    if length( firstLetters ) >= 1
        if length( firstLetters ) >= 3
            switch lower( firstLetters( 1 : 3 ) )
                case 'meg'
                    factor = 10 ^ 6;
                case 'mil'
                    factor = 25.4 * 10 ^ ( - 6 );
            end
            unitInFirstLetters = factor ~= 1 && length( firstLetters ) > 3;
        end
        if factor == 1
            switch lower( firstLetters( 1 ) )
                case 't'
                    factor = 10 ^ 12;
                case 'g'
                    factor = 10 ^ 9;
                case 'k'
                    factor = 10 ^ 3;
                case 'm'
                    factor = 10 ^ ( - 3 );
                case 'u'
                    factor = 10 ^ ( - 6 );
                case 'µ'
                    factor = 10 ^ ( - 6 );
                case 'n'
                    factor = 10 ^ ( - 9 );
                case 'p'
                    factor = 10 ^ ( - 12 );
                case 'f'
                    factor = 10 ^ ( - 15 );
            end
            unitInFirstLetters = length( firstLetters ) > 1;
        end
    else
        unitInFirstLetters = false;
    end
    if ~isempty( remainder ) && ( any( isstrprop( remainder , 'digit' ) ) || unitInFirstLetters )
        number = NaN;
        return;
    else
        number = number * factor;
    end
end
