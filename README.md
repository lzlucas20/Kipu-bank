# Kipu-bank
Smart contract de un banco para realizar depositos, retiros y tener una trazabilidad de cada movimiento
# 📋 Caracteristicas
Depósitos Personales: Los usuarios pueden depositar tokens nativos (ETH) en su bóveda personal     
Retiros Controlados: Límite fijo por transacción de retiro (configurable en el despliegue)    
Límite Global: Cap máximo de depósitos totales en el banco    
Seguimiento Completo: Registro de número de depósitos y retiros por usuario    
Seguridad: Implementa las mejores prácticas de seguridad de Solidity    

# INSTRUCCIONES PARA COMPILAR Y DESPLEGAR
1-Entra a https://remix.ethereum.org    
2-Crea un nuevo archivo llamado BancoKipu.sol    
3-Haz clic en el ícono de “Solidity Compiler”    
4-En “Compiler”, selecciona cualquier version >= 0.8.0    
5- Clic en el botón Compile BancoKipu.sol.    
✅ Si todo está bien, no aparecerán errores.    
# AHORA EL DESPLEGUE
Ve al ícono de “Deploy & Run Transactions”    
1- Podes usar tanto la red de prueba que te otorga remix o ir al apartado "Enviroment" y elegir "injected provider" metamask    
2-En los campos de constructor te pedirá:    
(siempre los valores se expresan en wei, NO en ETH)    
_limiteRetiro: por ejemplo 10000000000000000 (0.01 ETH).     
_capacidadBanco: por ejemplo 1000000000000000000 (1 ETH).    
3- Clic en Deploy 🟢    

# 🧠 Como interactuar con el contrato
Una vez desplegado, en la parte inferior de Remix verás tu contrato:    

depositar() → Enviás ETH (completá el campo “Value” arriba, por ejemplo 0.05 ether, y clic en depositar).    
retirar(monto) → Especificás cuánto querés retirar (en wei).    
obtenerSaldoBoveda(address) → Consultás el saldo de un usuario.    
registrosUsuario(address) → Muestra saldo, cantidad de depósitos y retiros.    
obtenerCapacidadRestante() → Te muestra cuánto espacio queda en el banco.

💡 Ejemplo de Uso Completo

1-Despliego con:

_limiteRetiro: 10000000000000000 (0.01 ETH por retiro)
_capacidadBanco: 1000000000000000000 (1 ETH total)


2-Deposito 0.5 ETH

Voy a depositar() → ingreso 0.5 en Value → Click en depositar
Evento emitido: Deposito(miDireccion, 500000000000000000, 500000000000000000)


3-Consulto mis registros

registrosUsuario(miDireccion) → Devuelve: saldo=500000000000000000, depositos=1, retiros=0


4-Retiro 0.01 ETH

retirar(10000000000000000) → Click
Evento emitido: Retiro(miDireccion, 10000000000000000, 490000000000000000)


5-Consulto capacidad restante

obtenerCapacidadRestante() → Devuelve: 500000000000000000 (0.5 ETH disponibles)
