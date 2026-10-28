#A partir de la nota numérica con decimales de un alumno, construye el programa que indique su calificación en 
# texto: Suspenso, Suficiente,Bien, etc.
n1=float(input("Dame el numero de la nota "))
if n1 < 5:
    print ("La nota es suspenso, puedes mejorar")
elif 5 <= n1 <= 6:
    print ("La nota esta aprobado pero mejorable ")
elif 6 <= n1 <= 8:
    print ("La nota es excelente")
elif n1 > 10:
    print ("La nota es erronea")
else:
    print ("Has sacado un sobre saliente")