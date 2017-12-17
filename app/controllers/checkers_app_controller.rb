class CheckersAppController < ApplicationController
	protect_from_forgery with: :null_session

	# marked true if no valid moves or all of one player's pieces are captured
	@@gameOver = false
	# delete tells move if a capture has been made, in which case we need to update an extra square
	@@delete = []
	# the current selected square
	@@from = [-1, -1]
	# 2D version of the current board
	@@board = []
	# stores the valid moves for the square currently selected
	@@currValidMoves = []
	# tells if we're in the middle of a jump chain (where the player must continue jumping if possible)
	@@inChain = false
	# moves allowed in the chain
	@@chainMoves = []


  	def index
  		puts "-----------In Index-----------"
  		@board = Board.all
  		if @board.size == 0
  			puts "Making new board!"
  			setBoard
  			@board = Board.last
  		else
  			@board = Board.last
  		end
  	end

  	def new
  		puts "-----------In New-----------"
  		respond_to do |format|
  			# create new board
  			setBoard
  			format.html{redirect_to "/"}
  		end
  	end

  	def select 
  		puts "-----------In Select-----------"
  		@@board = boardFromString

  		respond_to do |format|
  			if not @@gameOver
	  			@board = Board.last

	  			# fromRow = params[:fromRow]
	  			# fromCol = params[:fromCol]
	  			toRow = params[:toRow]
	  			toCol = params[:toCol]
		
	  			to = [toRow.to_i, toCol.to_i]
		
	  			if @@from[0] > -1
	  				# this is user's second click: make the move and reset @@from

	  				@@currValidMoves = getValidSquares(@@from) # for reference by other functions

	  				if moveValid?(@@from, to, @board.turn.to_i)
	  					move(@@from, to, @board.turn.to_i)
		
	  					printBoard(boardFromString())
	  				end
	  				@@from = [-1, -1]
	  				@board.update(validList: "")
	  			else
	  				# this is user's first click: save validList and set @@from
	  				@@from = [toRow.to_i, toCol.to_i]
	  				@@currValidMoves = getValidSquares(@@from)

		
	  				validString = toRow + toCol + "|"
	  				@@currValidMoves.each do |index|
	  					validString += index[0].to_s + index[1].to_s + "|"
	  				end
	  				puts "Got #{validString}"
	  				@board.update(validList: validString)
	  			end
	  		end
	
	  		format.html{redirect_to "/"}
		end
	end

	def setBoard
		newTurn = 1
		# trailing 1's avoid misinterpreting numbers with trailing 0's (e.g., 01010101)
		map = {"turn" => newTurn, "row1" => "101010101", "row2" => "110101010", "row3" => "101010101", "row4" => "100000000", "row5" => "100000000", "row6" => "120202020", "row7" => "102020202", "row8" => "120202020", "validList" => "", "gameOn" => "true"}

		newRow = Board.new(map)
		if newRow.save
			puts "Saved new board!"
		else
			puts "Failed to save new board."
		end
	end

	def moveValid?(from, to, player, verbose=true, moving=true)

		# if we're in the middle of a chain, only previously computed moves are valid
		if @@inChain
			if not @@chainMoves.include? to
				return false
			else
				$xDiff = to[0] - from[0]
				$yDiff = to[1] - from[1]

				$xCoord = from[0] + ($xDiff / 2)
				$yCoord = from[1] + ($yDiff / 2)

				@@delete += [$xCoord, $yCoord]

				return true
			end
		end

		# is it their move?
		if player.to_i != @board.turn.to_i
			if verbose
				puts "Not your turn!"
			end
			return false
		# in range?
		elsif not (from[0].between?(0, 7) and from[1].between?(0, 7) and to[0].between?(0, 7) and to[1].between?(0, 7))
			if verbose
				puts "Selected move out of range."
			end
			return false
		# is there a piece to start?
		elsif @@board[from[0]][from[1]] == "0"
			if verbose
				puts "Selected empty square!"
			end
			return false
		# is the current piece the player's?
		elsif @@board[from[0]][from[1]].to_i != player.to_i and @@board[from[0]][from[1]].to_i != player.to_i + 2
			if verbose
				puts "That's not your piece!"
			end
			return false
		# is the end spot available?
		elsif @@board[to[0]][to[1]] != "0"
			if verbose
				puts "That spot is taken!"
			end
			return false
		end

		# can't move backwards
		if player.to_i == 1
			# only if not king
			if @@board[from[0]][from[1]] == "1"
				if to[0] - from[0] < 0
					if verbose
						puts "P1: You can't move backwards!"
					end
					return false
				end
			end
		elsif player.to_i == 2
			if @@board[from[0]][from[1]] == "2"
				if from[0] - to[0] < 0
					if verbose
						puts "P2: You can't move backwards!"
					end
					return false
				end
			end
		end

		# is the move diagonal?
		$xDiff = to[0] - from[0]
		$yDiff = to[1] - from[1]
		if not $xDiff.abs == $yDiff.abs or $xDiff.abs > 2 or $yDiff.abs > 2
			if verbose
				puts "You must move diagonally."
			end
			return false
		# jumped a piece, then the piece in between must be the opponent's
		elsif $xDiff.abs == 2
			$xCoord = from[0] + ($xDiff / 2)
			$yCoord = from[1] + ($yDiff / 2)

			if @@board[$xCoord][$yCoord].to_i == player.to_i or @@board[$xCoord][$yCoord] == "0"
				if verbose
					puts "You can only jump over an opponent's piece."
				end
				return false
			end
			# don't add delete if you're just checking for valid moves (getValidSquares)
			if moving
				@@delete += [$xCoord, $yCoord]
			end
		else
			if @@inChain
				# if the only option is to jump, then xDiff must be 2
				return false
			end
		end

		return true
	end

	def boardFromString()
		# returns a normal array of numbers based on the string representation of the database
		# note: all values will be strings!
		@board = Board.last
		for i in 1..8
			name = "row" + i.to_s
			@@board[i - 1] = @board.send(:"#{name}").split("")
			@@board[i - 1].shift()
		end
		return @@board
	end

	def getValidSquares(index)
		# returns an array of all possible moves for a given square
		player = @board.turn

		validMoves = []

		# a piece has eight moves: four single diagonals, and four jump diagonals (only 4 if not king)
		for xSign in -1..1
			for ySign in -1..1
				if xSign != 0 and ySign != 0
					for dist in 1..2
						# alternates +/- 1, +/- 2 in each direction

						to = [index[0] + xSign * dist, index[1] + ySign * dist]

						puts "Trying #{to[0]}, #{to[1]}"
						if moveValid?(index, to, player, false, false)
							validMoves.push(to)
						end

					end
				end
			end
		end
		return validMoves
	end

	def setValue(index, value)
		# set a spot on the board to a certain value
		if index[0] == 0 or index[0] == 7 and value != 0
			# king me!
			if (value.to_i % 2) == 1
				value = 3
			else
				value = 4
			end
		end
		# in database, columns are row1, row2, etc. -- must increase by 1 to account for 0-based indexing
		name = "row" + (index[0] + 1).to_s
		row = @board.send(:"#{name}")
		# puts "Inside first is #{row}"
		row[index[1] + 1] = value.to_s # + 1 for leading 1
		# puts "Then is #{row}"
		@board.save
	end

	def move(from, to, player) 
  		puts "-----------In Move-----------"
  		puts "Moving to #{to}"
		newValue = @@board[from[0]][from[1]]
  		setValue(from, 0)
  		setValue(to, newValue)

  		# make any deletions specified by the moveValid method
  		# this also means the last move was a jump
  		if @@delete.size > 0
  			puts "Going to delete"
  			puts "Telling to delete (#{@@delete[0]}, #{@@delete[1]})"
  			setValue(@@delete, 0)

  			@@delete = []
  			@@chainMoves = []
  			@@board = boardFromString
  			# see if any more jumps are available (if not, next turn -- if so, player must move again)
  			newValidMoves = getValidSquares(to)
  			newValidMoves.each do |move|
  				$diff = move[0] - to[0]
  				if $diff.abs == 2
  					@@chainMoves.push(move)
  				end
  			end
  		end

  		puts "It's"
  		puts @@chainMoves

  		if @@chainMoves.size == 0
	  		# next player's turn
	  		@@inChain = false
			newTurn = @board.turn == 1 ? 2 : 1
  			@board.update(turn: newTurn)
  		else
  			@@inChain = true
  			puts "\n\nStarting chain\n\n"
  		end

  		if playerWon?
  			@@gameOver = true
  			@board.update(gameOn: "false")
  		end
	end

	def printBoard(board)
		for i in 0...8
			for j in 0...8
				print "#{board[i][j]} "
			end
			puts
		end
	end

	def playerWon?
		# game over if no valid moves or all of one player's pieces are gone
		board = boardFromString		

		if board.size > 0
			firstPlayerAlive = false
			secondPlayerAlive = false
			# while this will never be set again, if it were to be set true, would have returned already
			existMoves = false
			for i in 0..7
				for j in 0..7
					puts "Found #{@@board[i][j]}, #{@board.turn.to_i}"
					if (board[i][j].to_i % 2) == (@board.turn.to_i % 2) && board[i][j].to_i != 0
						puts "Checking for moves"
						validMoves = getValidSquares([i, j])
						if validMoves.size > 0
							puts "Valid moves!"
							return false
						end
					end
						
					if board[i][j] == "1" or board[i][j] == "3"
						firstPlayerAlive = true
					elsif board[i][j] == "2" or board[i][j] == "4"
						secondPlayerAlive = true
					end
				end
			end

			if not (firstPlayerAlive and secondPlayerAlive) or not existMoves
				puts "\n\n\n\nGAME OVER!!!!\n\n\n\n"
				return true
			else
				puts "not over!"
				return false
			end
		end
	end
end


# TODO:
# victory conditions
# just add a board instead of resetting
# allow multiple jumps
# what gem?
# new board button
# technically rules only allow multiple jumps in a straight line
