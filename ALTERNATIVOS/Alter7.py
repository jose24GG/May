#Programa que a partir de la medida de los lados de un triángulo, es capaz de decir si es equilátero, isósceles o escaleno.
lado1= int(input("Dame el primer del triangulo ")) 
lado2= int(input("Dame el segundo del triangulo ")) 
lado3= int(input("Dame el tecer lado del triangulo ")) 
if lado1==lado2==lado3:
    print ("Es un triangulo equilatero")
elif lado1==lado2 or lado2==lado3 or lado1==lado3:
    print ("Es un triangulo isosceles")
else:
    print ("Es un triangulo escaleno")