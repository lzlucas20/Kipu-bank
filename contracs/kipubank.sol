// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.0;
// smart contract de un banco para retirar, depositar ETH y llevar una trazabilidad del mismo
contract BancoKipu {
    // inmutables que se definen a la hora de deployar el contrato
    uint256 public immutable LIMITE_RETIRO;
    uint256 public immutable CAPACIDAD_BANCO;
    uint256 public constant DEPOSITO_MINIMO = 0.01 ether;
    // mapping para trackear las interacciones de cada usuario
    mapping(address => uint256) public bovedas;
    mapping(address => uint256) public userContadorDepositos;
    mapping(address => uint256) public userContadorRetiros;
    mapping(address => bool) private haDepositado;
   
    uint256 public totalDepositado;
    uint256 public totalUsuarios;
    
    // eventos que se emiten cuando un usuario deposita o retira ETH
    event Deposito(
        address indexed depositante, 
        uint256 monto, 
        uint256 nuevoSaldo
    );
    
    event Retiro(
        address indexed retirador, 
        uint256 monto, 
        uint256 saldoRestante
    );
    
    //      ------------------errores------------------- 
    error DepositoMuyPequeno();
    error CapacidadBancoExcedida(uint256 totalActual, uint256 intentoDeposito, uint256 capacidadBanco);
    error RetiroExcedeLimite(uint256 solicitado, uint256 limite);
    error SaldoInsuficiente(uint256 solicitado, uint256 disponible);
    error TransferenciaFallida();
    error MontoInvalido();
    error SinDepositos();

    // modificadores para definir mas adelante en las funciones 
    
    modifier montoValido(uint256 monto) {
        if (monto == 0) {
            revert MontoInvalido(); //en caso de depositar "0" se utiliza el error MontoInvalido
        }
        _; //me habia olvidado los guion bajo y me rompio la cabeza buscando que error tenia el contrato
    }
    
    modifier tieneSaldoBoveda() {
        if (bovedas[msg.sender] == 0) {
            revert SinDepositos();
        }
        _;
    }
    
    constructor(uint256 _limiteRetiro, uint256 _capacidadBanco) {
        require(_limiteRetiro > DEPOSITO_MINIMO, "Limite de retiro muy bajo");
        require(_capacidadBanco > DEPOSITO_MINIMO, "Capacidad del banco muy baja");
        require(_capacidadBanco > _limiteRetiro, "La capacidad debe exceder limite de retiro");
        
        LIMITE_RETIRO = _limiteRetiro;
        CAPACIDAD_BANCO = _capacidadBanco;
    }

    // ----------------funciones external-------------------
    
    function depositar() external payable montoValido(msg.value) {
        // -----checks-----
        if (msg.value < DEPOSITO_MINIMO) {
            revert DepositoMuyPequeno(); // error
        }
        
        if (totalDepositado + msg.value > CAPACIDAD_BANCO) {
            revert CapacidadBancoExcedida(totalDepositado, msg.value, CAPACIDAD_BANCO); // error
        }
        // -----effects-----
        if (!haDepositado[msg.sender]) {
            haDepositado[msg.sender] = true;
            totalUsuarios++;
        }
        
        bovedas[msg.sender] += msg.value;
        totalDepositado += msg.value;
        userContadorDepositos[msg.sender]++;
        // -----emit-----
        emit Deposito(msg.sender, msg.value, bovedas[msg.sender]);
    }
    
    function retirar(uint256 monto) external montoValido(monto) tieneSaldoBoveda {
        // -----checks-----
        if (monto > LIMITE_RETIRO) {
            revert RetiroExcedeLimite(monto, LIMITE_RETIRO); // error
        }
        
        uint256 saldoUsuario = bovedas[msg.sender];
        if (monto > saldoUsuario) {
            revert SaldoInsuficiente(monto, saldoUsuario); // error
        }
        // -----effects-----
        bovedas[msg.sender] -= monto;
        totalDepositado -= monto;
        userContadorRetiros[msg.sender]++;
        
        if (bovedas[msg.sender] == 0) {
            _actualizarEstadoUsuario(msg.sender); // se actualiza el stado del usuario si es 0
        }
        // -----emit-----
        emit Retiro(msg.sender, monto, bovedas[msg.sender]);
        // -----interactions-----
        (bool success, ) = msg.sender.call{value: monto}("");
        if (!success) {
            revert TransferenciaFallida(); // error
        }
    }
    // devuelve el saldo de un usuario en especifico 
    function obtenerSaldoBoveda(address usuario) external view returns (uint256 saldo) {
        return bovedas[usuario];
    }
    // devuelve el saldo, cantidad de depositos y cantidad de retiros de un usuario en especifico
    function registrosUsuario(address usuario) external view returns (
        uint256 saldo,
        uint256 depositos,
        uint256 retiros
    ) {
        return (
            bovedas[usuario],
            userContadorDepositos[usuario],
            userContadorRetiros[usuario]
        );
    }
    // devuelve la capacidad restante del banco
    function obtenerCapacidadRestante() external view returns (uint256 capacidadRestante) {
        return CAPACIDAD_BANCO - totalDepositado;
    }
    //  -----------funciones privadas------------
    function _actualizarEstadoUsuario(address usuario) private {
        if (bovedas[usuario] == 0 && haDepositado[usuario]) {
            haDepositado[usuario] = false;
            if (totalUsuarios > 0) {
                totalUsuarios--; // se actualiza la cantidad de usuarios cuando alguno llega a 0 de saldo
            }
        }
    }
    
    function _esDireccionValida(address addr) private pure returns (bool isValid) {
        return addr != address(0); // la direccion no puede ser 0x00....
    }
    
    // funcion para recibir ether directamente en el contrato
    receive() external payable {
        if (msg.value > 0) {
            this.depositar{value: msg.value}();
        }
    }
}
