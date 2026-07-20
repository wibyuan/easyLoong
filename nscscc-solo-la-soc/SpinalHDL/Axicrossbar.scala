package test

import spinal.core._
import spinal.lib._
import spinal.lib.bus.amba4.axi._
import spinal.lib.bus.amba4.axilite._
import spinal.lib.bus.amba4.axilite.AxiLite4Utils.Axi4Rich
import spinal.lib.bus.misc.SizeMapping
import javax.swing.text.FlowView

// -------------------------------------------

case class AxiCrossbar_2x8() extends Component {

  val inConfig = Axi4Config(
    addressWidth = 32,
    dataWidth    = 32,
    idWidth      = 4,
    useRegion    = false,
    useQos       = false
  )
  val outConfig = inConfig.copy(idWidth = inConfig.idWidth + 1)

  val io = new Bundle {
    val axiIn = Vec(slave(Axi4(inConfig)), size = 2)
    val axiOut = Vec(master(Axi4(outConfig)), size = 8)
    axiIn.foreach(Axi4SpecRenamer(_))
    axiOut.foreach(Axi4SpecRenamer(_))
  }

  noIoPrefix()

  val axiCrossBar = Axi4CrossbarFactory()

  axiCrossBar.addSlaves (
    (io.axiOut(0), SizeMapping(0x1c000000L, 8 MiB)),//sram
    (io.axiOut(1), SizeMapping(0x00000000L, 8 MiB)),//reserved
    (io.axiOut(2), SizeMapping(0x1f000000L, 1 MiB)),//apb
    (io.axiOut(3), SizeMapping(0x1f100000L, 1 MiB)),//dvi
    (io.axiOut(4), SizeMapping(0x1f200000L, 1 MiB)),//confreg
    (io.axiOut(5), SizeMapping(0x1f300000L, 1 MiB)),//dma
    (io.axiOut(6), SizeMapping(0x1f400000L, 1 MiB)),//fft
    (io.axiOut(7), SizeMapping(0x1f500000L, 1 MiB)) //reserved
  )

  axiCrossBar.addConnections(
    io.axiIn(0)     -> List(io.axiOut(0), io.axiOut(1), io.axiOut(2), io.axiOut(3), io.axiOut(4), io.axiOut(5), io.axiOut(6), io.axiOut(7)),
    io.axiIn(1)     -> List(io.axiOut(0), io.axiOut(1), io.axiOut(6), io.axiOut(7))
  )

  axiCrossBar.build()

}

// -------------------------------------------

object gen2x8 extends App {

  Config.spinal.generateVerilog(AxiCrossbar_2x8())
}
