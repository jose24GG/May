#Introducir una letra y visualizar si es vocal o consonante.
letra = input("Introduce una letra ").lower()
#Se puede hacer tambien con un if letra=='a' or letra=='e' or letra=='i' or letra=='o' or letra=='u':
if letra in "aeiou":
    print("Es una vocal")
else:
    print ("Es una consonante")