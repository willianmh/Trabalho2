for (i = 0; i < 8; i++) {
  if (isSet(callback_vector[i])){
    // verificar o limiar
    distancia = read_sonar();

    if (distancia < threshold[i]) {
      callFunction(function[i]);
      resetCallback(callback_vector[i]);
    }
  }
}


resetCallback(int n) {

}
