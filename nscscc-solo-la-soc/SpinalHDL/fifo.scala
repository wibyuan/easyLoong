package test

import spinal.core._
import spinal.lib._
import spinal.lib.bus.amba4.axi._

// -------------------------------------------

case class Axi_CDC() extends Component {

  val axiConfig = Axi4Config(
    addressWidth = 32,
    dataWidth    = 32,
    idWidth      = 5,
    useRegion    = false,
    useQos       = false
  )

  val io = new Bundle {
    val axiInClk = in Bool()
    val axiInRstn = in Bool()
    val axiOutClk = in Bool()
    val axiOutRstn = in Bool()
    val axiIn = slave(Axi4(axiConfig))
    val axiOut = master(Axi4(axiConfig))
    Axi4SpecRenamer(axiIn)
    Axi4SpecRenamer(axiOut)
  }

  noIoPrefix()

  val clockIn = ClockDomain(
    clock = io.axiInClk,
    reset = io.axiInRstn,
    config = ClockDomainConfig(
      clockEdge = RISING,
      resetKind = ASYNC,
      resetActiveLevel = LOW
    )
  )

  val clockOut = ClockDomain(
    clock = io.axiOutClk,
    reset = io.axiOutRstn,
    config = ClockDomainConfig(
      clockEdge = RISING,
      resetKind = ASYNC,
      resetActiveLevel = LOW
    )
  )

  //aw
  val awFifo = StreamFifoCC(
    dataType  = Axi4Aw(axiConfig),
    depth     = 4,
    pushClock = clockIn,
    popClock  = clockOut
  )
  awFifo.io.push << io.axiIn.aw
  awFifo.io.pop  >> io.axiOut.aw

  //w
  val wFifo = StreamFifoCC(
    dataType  = Axi4W(axiConfig),
    depth     = 8,
    pushClock = clockIn,
    popClock  = clockOut
  )
  wFifo.io.push << io.axiIn.w
  wFifo.io.pop  >> io.axiOut.w

  //b
  val bFifo = StreamFifoCC(
    dataType  = Axi4B(axiConfig),
    depth     = 4,
    pushClock = clockOut,
    popClock  = clockIn
  )
  bFifo.io.push << io.axiOut.b
  bFifo.io.pop  >> io.axiIn.b

  //ar
  val arFifo = StreamFifoCC(
    dataType  = Axi4Ar(axiConfig),
    depth     = 4,
    pushClock = clockIn,
    popClock  = clockOut
  )
  arFifo.io.push << io.axiIn.ar
  arFifo.io.pop  >> io.axiOut.ar

  //r
  val rFifo = StreamFifoCC(
    dataType  = Axi4R(axiConfig),
    depth     = 8,
    pushClock = clockOut,
    popClock  = clockIn
  )
  rFifo.io.push << io.axiOut.r
  rFifo.io.pop  >> io.axiIn.r

}

// -------------------------------------------

object genCDC extends App {

  Config.spinal.generateVerilog(Axi_CDC())
}

