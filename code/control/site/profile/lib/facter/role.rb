# This custom fact example splits the node hostname by dashes, then searches on the second item.
# Then sets the role name according to the first letter in that segment of the hostname.
Facter.add("role") do
  setcode do
    begin
      case Facter.value("hostname").split('-')[1]
      when /^f/i
	      'foo'
      when /^b/i
        'bar'
      when /^c/i
        'caz'
      when /^m/i
        'moo'
      when /^r/i
        'rar'
      when /^p/i
        'puppet'
      when /^s/i
        'section'
      end
    rescue
      nil
    end
  end
end
