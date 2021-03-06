#    This file is part of conwayrb.
#
#    conwayrb is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    conwayrb is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with conwayrb.  If not, see <http://www.gnu.org/licenses/>.

module Conway

  # Cells class holds the implementation details of the game.
  # The constructor creates an empty(!) square table holding the cells,
  # each being either alive or dead.
  # Manages counting the live neighbours or total cells alive as well as
  # re-populating the table based on whether the cells should stay alive, come
  # to life or die.
  # Contains convenience methods for checking cell's status and looping through
  # the whole table and running a lambda over each cell.
  class Cells

    def initialize(size_x, size_y)
      if size_x < 0 or size_y < 0
        fail(ArgumentError, 'Cells.new -> size cannot be negative!')
      elsif !size_x.is_a?(Fixnum) or !size_y.is_a?(Fixnum)
        fail(ArgumentError, 'Cells.new -> size has to be numeric!')
      end

      @size_x = size_x
      @size_y = size_y


      @array = Array.new(size_y) { Array.new(size_x, false) }
    end

    def alive?(x, y)
      @array[y][x]
    end

    def toggle(x, y)
      @array[y][x] = self.alive?(x, y) ? false : true
    end

    def size
      [@size_x, @size_y]
    end

    def add_life!(new_live_cells)
      if new_live_cells + self.total_lives > size.inject(1) { |a, b| a * b }
        raise(ArgumentError, 'Cannot add that many lives')
      end
      remaining_cells = new_live_cells

      while remaining_cells > 0
        x = rand(@size_x)
        y = rand(@size_y)

        unless alive?(x, y)
          @array[y][x] = true
          remaining_cells -= 1
        end
      end
    end

    def total_lives
      @array.flatten.count(true)
    end

    def live_neighbours(x, y)
      neighbours = Neighbours.all(x, y, @size)
      live_neighbours = 0

      neighbours.each do |rel_x, rel_y|
        live_neighbours += 1 if alive?(x + rel_x, y + rel_y)
      end

      live_neighbours
    end

    def map_of_alives
      alives = Array.new(@size_y) { Array.new(@size_x, 0) }
      every_cell do |x, y|
        if alive?(x, y)
          Neighbours.all(x, y, @size_x, @size_y).each do |rel_x, rel_y|
            alives[y + rel_y][x + rel_x] +=1
          end
        end
      end

      alives
    end

    def proceed!
      new_array = Array.new(@size_y) { Array.new(@size_x, false) }
      live_neighbour_map = map_of_alives

      every_cell do |x, y|
        if alive?(x, y)
          new_array[y][x] = (2..3).include? live_neighbour_map[y][x]
        else
          new_array[y][x] = (live_neighbour_map[y][x] == 3)
        end
      end

      @array = new_array
    end

    # Accepts a block, which can use the |x, y| coordinates of the cell
    def every_cell
      (0...@size_y).each do |y|
        (0...@size_x).each do |x|
          yield(x, y) if block_given?
        end
      end
    end
  end # ... of class Cells

  # Neighbours class manages providing the (relative) coordinates of a cell's
  # neighbours.
  class Neighbours
    def self.all(x, y, limit_x, limit_y)
      neighbours = []
      neighbours.push(*diagonal(x, y, limit_x, limit_y))
      neighbours.push(*vertical(y, limit_y))
      neighbours.push(*horizontal(x, limit_x))

      neighbours
    end

    def self.horizontal(x, limit)
      x_range = limits(x, limit)
      x_range.size == 2 ? x_range.zip([0, 0]) : [[x_range[0], 0]]
    end

    def self.vertical(y, limit)
      y_range = limits(y, limit)
      y_range.size == 2 ? [0, 0].zip(y_range) : [[0, y_range[0]]]
    end

    def self.diagonal(x, y, limit_x, limit_y)
      x_range = horizontal(x, limit_x)
      y_range = vertical(y, limit_y)
      diag_range = []

      x_range.each do |x_off, _x|
        y_range.each do |_y, y_off|
          diag_range << [x_off, y_off]
        end
      end

      diag_range
    end

    def self.limits(value, max)
      max_values = []
      max_values << -1 unless value == 0
      max_values << 1 unless value == max - 1

      max_values
    end
  end # ... of class Neighbours
end # ... of module Conway
