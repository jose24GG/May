#Introducir la medida en números enteros de un triángulo y visualizar si es equilátero o no.
lado1= int(input("Dame el primer del triangulo ")) 
lado2= int(input("Dame el segundo del triangulo ")) 
lado3= int(input("Dame el tecer lado del triangulo ")) 
if lado1==lado2==lado3:
    print ("Es un triangulo equilatero")
else:
    print ("No es un triangulo equilatero")