
class Integer
  def prime_divisors
    factors = []
    (2..abs).each do |number|
      factors << number if (self % number == 0) && factors.all? { |factor| number % factor != 0 }
    end
    factors
  end
end

class Range
  def fizzbuzz
    map do |n|
      if n % 15 == 0
        :fizzbuzz
      elsif n % 5 == 0
        :buzz
      elsif n % 3 == 0
        :fizz
      else
        n
      end
    end
  end
end

class Hash
  def group_values
    result = {}
    each do |key, value|
      result[value] ||= []
      result[value] << key
    end
    result
  end
end

class Array
  def densities
    map { |element| count(element) }
  end
end

