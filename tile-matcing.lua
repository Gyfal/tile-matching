local GAME_RULES = {
    count_rows = 10,
    count_colums = 10,
    count_colors = { 'A', 'B', 'C', 'D', 'E', 'F' },
    min_group_size = 3,
    states_key = { "move", "mix", "error", "wait" },
    states = {},
}

local EMPTY_CELL = "-"

-- revers states
-- GAME_RULES.states[ "wait" ] = 1
for k, v in pairs( GAME_RULES.states_key ) do
    GAME_RULES.states[ v ] = k
end


function createGame()
    local GAME = {
        board = {},
        state = GAME_RULES.states[ "wait" ]
    }

    function GAME:setGameState( id )
        self.state = GAME_RULES.states[ id ] or GAME_RULES.states[ "error" ]
        return self
    end

    function GAME:getGameState()
        return self.state
    end

    function GAME:removeField( row, colum )
        self.board[ row ][ colum ] = EMPTY_CELL
    end

    function GAME:getFieldItem( row, colum )
        if not self.board[ row ] then return false end
        return self.board[ row ][ colum ] or false
    end

    function GAME:dump()
        print( '===================')
        io.write( "\t", "\t" )
        for k = 0, #self.board do
            io.write( k, " \t" )
        end 
        io.write( "\n\t", " \t" )
        for k = 0, #self.board do
            io.write( "-", " \t" )
        end 
        io.write( "\n" )
        local count = #self.board
        for row = 0, count do
            io.write( row, "\t | \t" )
            
            for colum = 0, #self.board[ row ] do
                io.write( self.board[ row ][ colum ], "\t" )
            end
            io.write( "\n" )
        end
       
        return self
    end

    function GAME:isCombo( row, colum, value )
        return self:isVerticalCombo( row, colum, value ) or self:isHorizontalCombo( row, colum, value ) or false
    end

    function GAME:INIT_DEBUG()
        -- debug доска, на которой только 1 ход доступен 0 4
        self.board = {
            [ 0 ] = 
            { [ 0 ] = "1", "2", "3", "4", "A", "5", "6", "7", "8", "9", },
            { [ 0 ] = "10", "11", "12", "A", "13", "A", "14", "15", "16", "17", },
            { [ 0 ] = "18", "19", "20", "21", "22", "23", "24", "25", "26", "27",  },
            { [ 0 ] = "18", "19", "20", "21", "22", "23", "24", "25", "26", "27",  },
            { [ 0 ] = "1", "2", "3", "4", "A", "5", "6", "7", "8", "9", },
            { [ 0 ] = "1-", "22", "32", "42", "A2", "52", "62", "72", "82", "92", },
            { [ 0 ] = "18", "19", "20", "21", "22", "23", "24", "25", "26", "27",  },
            { [ 0 ] = "1", "2", "3", "4", "з", "5", "6", "7", "8", "9", },
            { [ 0 ] = "1", "2", "3", "4", "ж", "5", "6", "7", "8", "9", },
            { [ 0 ] = "18", "19", "20", "21", "22", "23", "24", "25", "26", "27",  },
            { [ 0 ] = "A", "B", "C", "E", "б", "B", "C", "E", "A", "B", },
        }
        return self
    end

    function GAME:isVerticalCombo( row, colum, fake_value, debug )
        local value = fake_value or self:getFieldItem( row, colum )
        local combo_count = 1
        local start = row

        while self:getFieldItem( start + 1, colum ) == value do
            start = start + 1
            combo_count = combo_count + 1
        end
        
        start = row
        
        while self:getFieldItem( start - 1, colum ) == value do
            start = start - 1
            combo_count = combo_count + 1
        end
        
        return combo_count >= GAME_RULES.min_group_size
    end

    function GAME:isHorizontalCombo( row, colum, fake_value, debug )
        local value = fake_value or self:getFieldItem( row, colum )
        local combo_count = 1
        local start = colum
        
        while self:getFieldItem( row, start + 1 ) == value do
            start = start + 1
            combo_count = combo_count + 1
        end
        
        start = colum
        
        while self:getFieldItem( row, start - 1 ) == value do
            start = start - 1
            combo_count = combo_count + 1
        end

        return combo_count >= GAME_RULES.min_group_size
    end

    function GAME:mix()
        for row = 0, GAME_RULES.count_rows -1 do
            self.board[ row ] = {}
                for colum = 0, GAME_RULES.count_colums -1 do
                    repeat
                        self.board[ row ][ colum ] = self:newCrystal() --
                    until not self:isCombo( row, colum )
                end
            end
        return self
    end

    function GAME:newCrystal()
        return GAME_RULES.count_colors[ math.random( 1, #GAME_RULES.count_colors )]
    end


    function GAME:removeAndShift( )
        
        -- Поднимаемтся по row, ищем ближайший
        local function get_top_item( row, colum )
            local start = row
            for i = start, 0, -1 do
                local value = self:getFieldItem( i, colum )
                if value and value ~= EMPTY_CELL then
                    return i, colum
                end
            end
            return false
        end

        -- Поднимаемся снизу вверх, и смещаем пустые ячейки
        for row = #self.board, 0, -1 do
            for colum = 0, #self.board[0] do
                if self:getFieldItem( row, colum ) == EMPTY_CELL then
                    local top_row, top_colum = get_top_item( row, colum )
                    if not top_row then -- Если мы дошли до 0 и не нашли что сместить - создаем рандомный
                        repeat
                            self.board[ row ][ colum ] = self:newCrystal()
                        until not self:isCombo( row, colum )
                    else -- Перезаписываем
                        self:swap( { row, colum }, { top_row, top_colum } )
                    end
                end
            end
        end
    end

    -- Проверка на то что есть доступные ходы
    function GAME:isAbilityMove()
        for row = 0, GAME_RULES.count_rows - 1 do
            for colum = 0, GAME_RULES.count_colums - 1 do
                for offset = -1, 1, 2 do -- На 1 ячейку назад и на 1 ячейку вперед
                    if self:isCanMove( { row, colum }, { row, colum + offset } ) then
                        return row, colum, row, colum + offset
                    end
                    if self:isCanMove( { row, colum }, { row + offset, colum } ) then
                        return row, colum, row + offset, colum
                   end
                end
            end
        end
        return false
    end

    function GAME:removeComboLine( row, colum )
        if not self:isCombo( row, colum ) then return false end

        local value = self:getFieldItem( row, colum )
        
        if self:isVerticalCombo( row, colum ) then
            local start = row
            while self:getFieldItem( start + 1, colum ) == value do
                start = start + 1
                self:removeField( start, colum )
            end
            
            start = row
            
            while self:getFieldItem( start - 1, colum ) == value do
                start = start - 1
                self:removeField( start, colum )
            end
        end

        if self:isHorizontalCombo( row, colum ) then
            local start = colum
            while self:getFieldItem( row, start + 1 ) == value do
                start = start + 1
                self:removeField( row, start )
            end
            
            start = colum
            
            while self:getFieldItem( row, start - 1 ) == value do
                start = start - 1
                self:removeField( row, start )
            end
        end

        self:removeField( row, colum )

        return true
    end

    function GAME:tick()
        if self:getGameState() == GAME_RULES.states.move then
            self:removeAndShift()
        end
        if not self:isAbilityMove( ) then
            print("Couldn't find available moves, mix!")
            self:mix()
            self:tick()
        end
        
    end

    function GAME:swap( from, to )
        local from_value = self:getFieldItem( from[1], from[2] )
        local to_value = self:getFieldItem( to[1], to[2] )

        self.board[ from[1] ][ from[2] ] = to_value
        self.board[ to[1] ][ to[2] ] = from_value
    end

    function GAME:isCanMove( from, to, debus )
        local from_value = self:getFieldItem( from[1], from[2] )
        local to_value = self:getFieldItem( to[1], to[2] )
        if not from_value or not to_value then return end

        if from[1] == to[1] and from[2] == to[2] then
            return false
        end

        if math.abs( from[1] - to[1] ) > 1 or math.abs( from[ 2 ] - to[ 2 ] ) > 1 then
            return false
        end

        self:swap( from, to )
        local is_success = self:isCombo( from[ 1 ], from[ 2 ], to_value ) or self:isCombo( to[ 1 ], to[ 2 ], from_value )
        self:swap( to, from )

        return is_success
    end


    function GAME:move( from, to )
       if not self:isCanMove( from, to ) then return end

       self:swap( from, to )

       self:removeComboLine( from[1], from[2] )
       self:removeComboLine( to[1], to[2] )

       return self
    end

    function GAME:init()
        self:mix()
        -- self:INIT_DEBUG()

        while true do
            self:dump()
            self:setGameState( "wait" )
            -- ждем ввода от пользователя
            local input = io.read()
            local x, y, dir = input:math( "^m%s+%d+%s+%d+%w" )

            if input == "q" then
                break
            -- elseif input == "reset" then
            --     self:INIT_DEBUG()
            -- elseif input == "if" then
            --     print( self:isAbilityMove() )
            elseif x and y and dir then

                local to_x, to_y
                if dir == "l" then
                    to_x, to_y = x, y - 1
                elseif dir == "r" then
                    to_x, to_y = x, y + 1
                elseif dir == "u" then
                    to_x, to_y = x - 1, y
                elseif dir == "d" then
                    to_x, to_y = x + 1, y
                end

                
                if not self:getFieldItem( to_x, to_y ) then
                    self:setGameState( "error" )
                else
                    local boolean = self:move( { x, y }, { to_x, to_y } )
                    if not boolean then
                        self:setGameState( "error" )
                        print( "field not update" )
                    else
                        self:setGameState( "move" )
                        print( "field success" )
                    end
                end
            else
                print( "error input. example: m 3 0 r" )
            end

            if self:getGameState() ~= GAME_RULES.states.error then
                self:tick()
            end
        end
    end
    return GAME
end



GAME = createGame()
GAME:init()