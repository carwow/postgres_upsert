class PostgresDumbWriter < PostgresWriter

  def initialize(table_name, source, options = {})
    @table_name = table_name
    @options = options.reverse_merge({
      :delimiter => ",", 
      :format => :csv, 
      :header => true, 
      :key_column => primary_key,
      :update_only => false})
    @source = source.instance_of?(String) ? File.open(source, 'r') : source
    @columns_list = get_columns
    generate_temp_table_name
  end


private

  def primary_key
    @primary_key ||= begin
      query = <<-sql
        SELECT
          pg_attribute.attname,
          format_type(pg_attribute.atttypid, pg_attribute.atttypmod)
        FROM pg_index, pg_class, pg_attribute
        WHERE
          pg_class.oid = '#{@table_name}'::regclass AND
          indrelid = pg_class.oid AND
          pg_attribute.attrelid = pg_class.oid AND
          pg_attribute.attnum = any(pg_index.indkey)
        AND indisprimary
      sql

      pg_result = ActiveRecord::Base.connection.execute query
      pg_result.each{ |row| return row['attname'] }
    end
  end

  def column_names
    @column_names ||= begin
      query = "SELECT * FROM information_schema.columns WHERE TABLE_NAME = '#{@table_name}'"
      pg_result = ActiveRecord::Base.connection.execute query
      pg_result.map{ |row| row['column_name'] }
    end
  end

  def quoted_table_name
    @quoted_table_name ||= ActiveRecord::Base.connection.quote_table_name(@table_name)
  end
  
end
