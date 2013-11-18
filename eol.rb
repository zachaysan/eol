# -*- coding: utf-8 -*-
require 'pp'

filename = "./spec"
program_string = File.read(filename)

program = []
program_string.split("\n").each do |line|
  if line == "eoeol"
    break
  elsif line[0] == "#"
    next
  elsif line == ""
    next
  end
  program << line
end

puts program
puts ""

tokens = {}

class Node
  attr_accessor :parent, :left, :right, :action, :value, :complete

  def initialize
    self.complete = false
  end

  def immediate_return
    return self.value
  end

  def symbolic_return
    return "get value of: " + self.value.to_s
  end

  def provides
    variables = []
    variables << self.left.value if self.action == :make_equal
    variables += self.left.provides if self.left
    variables += self.right.provides if self.right
    self.complete = true
    variables
  end

  def depends
    variables = []
    parent_setter = !self.parent.nil? && self.parent.action == :make_equal
    symbolic_return = self.action == :symbolic_return
    variables << self.value if symbolic_return unless parent_setter
    variables += self.left.depends if self.left
    variables += self.right.depends if self.right
    variables
  end

  def to_s(padding=0)
    resp = ""
    pad = '  ' * padding
    resp = ["action: #{self.action}",
            "value: #{self.value}"].map {|e| pad + e}

    resp = resp.join("\n")
    if self.left
      resp += "\n#{pad}left:\n"
      resp += self.left.to_s(padding+1)
    end
    if self.right
      resp += "\n#{pad}right:\n"
      resp += self.right.to_s(padding+1)
    end
    if padding < 1
      resp += "\n"
    end
    resp
  end
end

def tokenize_line(line)
  tokens = line.split(" ")
  node = Node.new
  return tokenize_segment(tokens, node)
end

def tokenize_segment(tokens, node)
  if tokens.include? "="
    node.action = :make_equal
    split_nodes(node, tokens, "=")

  elsif tokens.include? "+"
    node.action = :add
    split_nodes(node, tokens, "+")

  elsif tokens[0] == "puts"
    node.action = :puts
    split_nodes(node, tokens, "puts")

  elsif tokens.length == 1
    token = tokens[0]
    tokenize(token, node)
  end
  if node.parent.nil?
    puts node.to_s
    puts ""
  end
  return node
end

def split_nodes(node, tokens, token_symbol)
  token_index = tokens.index token_symbol  

  left_tokens = tokens[0...token_index]

  if left_tokens.length > 0
    left_node = Node.new
    left_node.parent = node
    node.left = left_node
    tokenize_segment(left_tokens, left_node)
  end

  right_tokens = tokens[(token_index + 1)..-1]

  if right_tokens.length > 0
    right_node = Node.new
    right_node.parent = node
    node.right = right_node
    tokenize_segment(right_tokens, right_node)
  end
end

def tokenize(token, node)
  keywords = ["print", "puts"]
  if token_is_int(token)
    node.action = :immediate_return
    node.value = token
  elsif keywords.include? token

  else
    node.action = :symbolic_return
    node.value = token
  end
end

def token_is_int(token)
  token.to_i.to_s == token
end

tokenized_program = program.map do |line|
  tokenize_line(line)
end

def sandwhich(symbol, node)
    acc = ""
    acc += translate_node(node.left) if node.left
    acc += symbol
    acc += translate_node(node.right) if node.right
    acc
end

def translate_node(node)
  if node.action == :symbolic_return
    "#{node.value}"
  elsif node.action == :immediate_return
    "#{node.value}"
  elsif node.action == :make_equal
    sandwhich(" := ", node)
  elsif node.action == :add
    sandwhich(" + ", node)
  elsif node.action == :puts
    if node.right
      "fmt.Println(" + translate_node(node.right) + ")"
    else
      'fmt.Println("")'
    end
  else
    raise "Not Implemented"
  end
end
go_program = <<-eos
package main

import "fmt"

func main() {
eos

def run_program(tokenized_program, go_program)
  complete = tokenized_program.map{ | parent_node | parent_node.complete }.all?

  pp tokenized_program
  while not complete
    complete = tokenized_program.map do | parent_node | 
      puts "provides: #{parent_node.provides} depends: #{parent_node.depends}"
      
      go_program += translate_node(parent_node)
      go_program += "\n"
      parent_node.complete
    end.all?
  end

  go_program += '}'

  puts go_program

  File.open("temp.go", 'w') {|f| f.write(go_program) }
  `go build temp.go`
  foo = `./temp`
  puts foo
end

run_program(tokenized_program, go_program)
