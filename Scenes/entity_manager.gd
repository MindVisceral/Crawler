extends Node2D

## This script keeps track of all Entities present on in the given Room to allow
## them access to other such Entities

## Dynamic Array of all living Entities currently present in the Room
var entities: Array[StaticBody2D]
