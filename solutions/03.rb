class Expr
  def self.build(tree)
    if tree.size > 2
      Binary.build tree
    else
      Unary.build tree
    end
  end
end

class Unary < Expr
  attr_accessor :operand
  def initialize(operand)
    @operand = operand
  end

  def self.build(tree)
    operation = tree[0]
    case operation
      when :-         then  Negation.new Expr.build(tree[1])
      when :sin       then  Sine    .new Expr.build(tree[1])
      when :cos       then  Cosine  .new Expr.build(tree[1])
      when :variable  then  Variable.new tree[1]
      when :number    then  Number  .new tree[1]
    end
  end

  def ==(other)
    if self.class == other.class and operand == other.operand
      true
    else
      false
    end
  end

  def simplify
    self
  end
end

class Number < Unary
  def evaluate(environment = {})
    operand
  end

  def derive(variable)
    Number.new 0
  end

  def exact?
    true
  end

  def to_s
    "#{operand}"
  end
end

class Variable < Unary
  def evaluate(environment = {})
    if environment.has_key? operand
      environment[operand]
    else
      raise "Undifined variable #{operand} !"
    end
  end

  def derive(variable)
    if operand == variable
      Number.new 1
    else
      Number.new 0
    end
  end

  def exact?
    false
  end

  def to_s
    "#{operand}"
  end
end

class Negation < Unary
  def evaluate(environment = {})
    -operand.evaluate(environment)
  end

  def derive(variable)
    Negation.new(operand.derive(variable)).simplify
  end

  def exact?
    operand.exact?
  end

  def simplify
    if exact?
      Number.new -operand.evaluate
    else
      self
    end
  end

  def to_s
    "-#{operand}"
  end
end

class Sine < Unary
  def evaluate(environment = {})
    Math.sin(operand.evaluate(environment))
  end

  def derive(variable)
    Multiplication.new(operand.derive(variable), Cosine.new(operand)).simplify
  end

  def exact?
    operand.exact?
  end

  def simplify
    if exact?
      Number.new Math.sin(operand.evaluate)
    else
      self
    end
  end

  def to_s
    "sin(#{operand})"
  end
end

class Cosine < Unary
  def evaluate(environment = {})
    Math.cos(operand.evaluate(environment))
  end

  def derive(variable)
    Multiplication.new(operand.derive(variable), Negation.new(Sine.new(operand))).simplify
  end

  def exact?
    operand.exact?
  end

  def simplify
    if exact?
      Number.new Math.cos(operand.evaluate)
    else
      self
    end
  end

  def to_s
    "cos(#{operand})"
  end
end

class Binary < Expr
  attr_accessor :left_operand, :right_operand
  def initialize(left_operand, right_operand)
    @left_operand  = left_operand
    @right_operand = right_operand
  end

  def self.build(tree)
    operation, left_operand, right_operand = tree
    case operation
      when :+
        Addition.new Expr.build(left_operand), Expr.build(right_operand)
      when :*
        Multiplication.new Expr.build(left_operand), Expr.build(right_operand)
    end
  end

  def ==(other)
    if self.class    == other.class         and
       left_operand  == other.left_operand  and
       right_operand == other.right_operand
      true
    else
      false
    end
  end
end

class Addition < Binary
  def evaluate(environment = {})
    left_operand.evaluate(environment) + right_operand.evaluate(environment)
  end

  def derive(variable)
    Addition.new(left_operand.derive(variable), right_operand.derive(variable)).simplify
  end

  def exact?
    if left_operand.exact? and right_operand.exact?
      true
    else
      false
    end
  end

  def simplify
    if exact?
      Number.new evaluate
    elsif left_operand.exact?  and left_operand.evaluate  == 0
      right_operand.simplify
    elsif right_operand.exact? and right_operand.evaluate == 0
      left_operand.simplify
    else
      Addition.new left_operand.simplify, right_operand.simplify
    end
  end

  def to_s
    "(#{left_operand} + #{right_operand})"
  end
end

class Multiplication < Binary
  def evaluate(environment = {})
    if (left_operand.exact?  and left_operand.evaluate  == 0) or
       (right_operand.exact? and right_operand.evaluate == 0)
      0
    else
      left_operand.evaluate(environment) * right_operand.evaluate(environment)
    end
  end

  def derive(variable)
    new_left_operand  = Multiplication.new left_operand.derive(variable), right_operand
    new_right_operand = Multiplication.new left_operand, right_operand.derive(variable)
    Addition.new(new_left_operand, new_right_operand).simplify
  end

  def exact?
    if (left_operand.exact?  and right_operand.exact?)        or
       (left_operand.exact?  and left_operand.evaluate  == 0) or
       (right_operand.exact? and right_operand.evaluate == 0)
      true
    else
      false
    end
  end

  def simplify
    if exact?
      Number.new(evaluate)
    elsif (left_operand.exact?  and left_operand.evaluate  == 0) or
          (right_operand.exact? and right_operand.evaluate == 0)
      Number.new(0)
    elsif left_operand.exact?   and left_operand.evaluate  == 1
      right_operand.simplify
    elsif right_operand.exact?  and right_operand.evaluate == 1
      left_operand.simplify
    else
      Multiplication.new left_operand.simplify, right_operand.simplify
    end
  end

  def to_s
    "#{left_operand} * #{right_operand}"
  end
end