require_relative 'map_formulae_to_ruby'

class CompileToRuby
  
  attr_accessor :settable
  attr_accessor :worksheet
  attr_accessor :defaults
  
  def self.rewrite(*args)
    self.new.rewrite(*args)
  end
  
  def rewrite(input, sheet_names, output, sheet_values)
    self.settable ||= lambda { |ref| false }
    self.defaults ||= []
    mapper = MapFormulaeToRuby.new
    mapper.sheet_names = sheet_names
    puts sheet_values
    puts mapper.sheet_names

    input.each do |ref, ast|
      begin

        worksheet = ref.first.to_s
        cell = ref.last
        mapper.worksheet = worksheet
        worksheet_c_name = mapper.sheet_names[worksheet] || worksheet.to_s
        row, column = cell.to_s.split(/(\D+)/).reject { |n| n.length == 0 }
        if row == "A" || column == "1"
          cell_name = cell.downcase
        else

        puts cell
        puts "key #{key_for_cell(worksheet, "A#{column}")}"
        col_name = sheet_values[key_for_cell(worksheet, "A#{column}")]&.last || ""
        row_name = sheet_values[key_for_cell(worksheet, "#{row}1")]&.last || ""
        cell_name = underscore(col_name + row_name)
        puts "name #{cell_name}"
        end
        name = worksheet_c_name.length > 0 ? "#{worksheet_c_name}_#{cell_name.downcase}" : cell_name.downcase
        next if ast[0].to_s == "string"

        if settable.call(ref)
          output.puts "  attr_accessor :#{name} # Default: #{mapper.map(ast)}"
          defaults << "    @#{name} = #{mapper.map(ast)}"
        else
          output.puts "  def #{name}; @#{name} ||= #{mapper.map(ast)}; end"
        end
      rescue Exception => e
        puts "Exception at #{ref} => #{ast}"
        raise
      end      
    end
  end

  def key_for_cell(worksheet_name, cell)
    if worksheet_name.length > 0
      [worksheet_name.to_sym, cell.to_sym]
    else
      cell.to_sym
    end
  end

  def underscore(sentence)
    words = sentence.split(/\s+/)
    snake_case_words = words.map(&:downcase)
    snake_case_sentence = snake_case_words.join('_')
    snake_case_sentence
  end
end
