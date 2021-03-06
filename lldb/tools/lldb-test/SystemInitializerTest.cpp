//===-- SystemInitializerTest.cpp -------------------------------*- C++ -*-===//
//
// Part of the LLVM Project, under the Apache License v2.0 with LLVM Exceptions.
// See https://llvm.org/LICENSE.txt for license information.
// SPDX-License-Identifier: Apache-2.0 WITH LLVM-exception
//
//===----------------------------------------------------------------------===//

#include "SystemInitializerTest.h"
#include "lldb/Core/Debugger.h"
#include "lldb/Core/PluginManager.h"
#include "lldb/Host/Host.h"
#include "lldb/Initialization/SystemInitializerCommon.h"
#include "lldb/Interpreter/CommandInterpreter.h"
#include "lldb/Utility/Timer.h"
#include "llvm/Support/TargetSelect.h"

#include <string>

LLDB_PLUGIN_DECLARE(ABIAArch64)
LLDB_PLUGIN_DECLARE(ABIARM)
LLDB_PLUGIN_DECLARE(ABIARC)
LLDB_PLUGIN_DECLARE(ABIHexagon)
LLDB_PLUGIN_DECLARE(ABIMips)
LLDB_PLUGIN_DECLARE(ABIPowerPC)
LLDB_PLUGIN_DECLARE(ABISystemZ)
LLDB_PLUGIN_DECLARE(ABIX86)
LLDB_PLUGIN_DECLARE(ObjectFileBreakpad)
LLDB_PLUGIN_DECLARE(ObjectFileELF)
LLDB_PLUGIN_DECLARE(ObjectFileMachO)
LLDB_PLUGIN_DECLARE(ObjectFilePECOFF)
LLDB_PLUGIN_DECLARE(ObjectFileWasm)
LLDB_PLUGIN_DECLARE(ObjectContainerBSDArchive)
LLDB_PLUGIN_DECLARE(ObjectContainerMachOArchive)
LLDB_PLUGIN_DECLARE(ScriptInterpreterNone)
LLDB_PLUGIN_DECLARE(PlatformFreeBSD)
LLDB_PLUGIN_DECLARE(PlatformLinux)
LLDB_PLUGIN_DECLARE(PlatformNetBSD)
LLDB_PLUGIN_DECLARE(PlatformOpenBSD)
LLDB_PLUGIN_DECLARE(PlatformWindows)
LLDB_PLUGIN_DECLARE(PlatformAndroid)
LLDB_PLUGIN_DECLARE(PlatformMacOSX)
LLDB_PLUGIN_DECLARE(TypeSystemClang)
LLDB_PLUGIN_DECLARE(ArchitectureArm)
LLDB_PLUGIN_DECLARE(ArchitectureMips)
LLDB_PLUGIN_DECLARE(ArchitecturePPC64)
LLDB_PLUGIN_DECLARE(DisassemblerLLVMC)
LLDB_PLUGIN_DECLARE(JITLoaderGDB)
LLDB_PLUGIN_DECLARE(ProcessElfCore)
LLDB_PLUGIN_DECLARE(ProcessMachCore)
LLDB_PLUGIN_DECLARE(ProcessMinidump)
LLDB_PLUGIN_DECLARE(MemoryHistoryASan)
LLDB_PLUGIN_DECLARE(InstrumentationRuntimeASan)
LLDB_PLUGIN_DECLARE(InstrumentationRuntimeTSan)
LLDB_PLUGIN_DECLARE(InstrumentationRuntimeUBSan)
LLDB_PLUGIN_DECLARE(InstrumentationRuntimeMainThreadChecker)
LLDB_PLUGIN_DECLARE(SymbolVendorELF)
LLDB_PLUGIN_DECLARE(SymbolFileBreakpad)
LLDB_PLUGIN_DECLARE(SymbolFileDWARF)
LLDB_PLUGIN_DECLARE(SymbolFilePDB)
LLDB_PLUGIN_DECLARE(SymbolFileSymtab)
LLDB_PLUGIN_DECLARE(SymbolVendorWasm)
LLDB_PLUGIN_DECLARE(UnwindAssemblyInstEmulation)
LLDB_PLUGIN_DECLARE(UnwindAssemblyX86)
LLDB_PLUGIN_DECLARE(InstructionARM)
LLDB_PLUGIN_DECLARE(InstructionARM64)
LLDB_PLUGIN_DECLARE(InstructionMIPS)
LLDB_PLUGIN_DECLARE(InstructionMIPS64)
LLDB_PLUGIN_DECLARE(InstructionPPC64)
LLDB_PLUGIN_DECLARE(CXXItaniumABI)
LLDB_PLUGIN_DECLARE(AppleObjCRuntime)
LLDB_PLUGIN_DECLARE(SystemRuntimeMacOSX)
LLDB_PLUGIN_DECLARE(RenderScriptRuntime)
LLDB_PLUGIN_DECLARE(CPlusPlusLanguage)
LLDB_PLUGIN_DECLARE(ObjCLanguage)
LLDB_PLUGIN_DECLARE(ObjCPlusPlusLanguage)
#if defined(_WIN32)
LLDB_PLUGIN_DECLARE(ProcessWindowsCommon)
#endif
#if defined(__FreeBSD__)
LLDB_PLUGIN_DECLARE(ProcessFreeBSD)
#endif
#if defined(__APPLE__)
LLDB_PLUGIN_DECLARE(SymbolVendorMacOSX)
LLDB_PLUGIN_DECLARE(ProcessMacOSXKernel)
LLDB_PLUGIN_DECLARE(DynamicLoaderDarwinKernel)
#endif
LLDB_PLUGIN_DECLARE(StructuredDataDarwinLog)
LLDB_PLUGIN_DECLARE(PlatformGDB)
LLDB_PLUGIN_DECLARE(ProcessGDBRemote)
LLDB_PLUGIN_DECLARE(DynamicLoaderMacOSXDYLD)
LLDB_PLUGIN_DECLARE(DynamicLoaderPosixDYLD)
LLDB_PLUGIN_DECLARE(DynamicLoaderStatic)
LLDB_PLUGIN_DECLARE(DynamicLoaderWasmDYLD)
LLDB_PLUGIN_DECLARE(DynamicLoaderWindowsDYLD)

using namespace lldb_private;

SystemInitializerTest::SystemInitializerTest() {}

SystemInitializerTest::~SystemInitializerTest() {}

#define LLDB_PROCESS_AArch64(op) op(ABIAArch64);
#define LLDB_PROCESS_ARM(op) op(ABIARM);
#define LLDB_PROCESS_ARC(op) op(ABIARC);
#define LLDB_PROCESS_Hexagon(op) op(ABIHexagon);
#define LLDB_PROCESS_Mips(op) op(ABIMips);
#define LLDB_PROCESS_PowerPC(op) op(ABIPowerPC);
#define LLDB_PROCESS_SystemZ(op) op(ABISystemZ);
#define LLDB_PROCESS_X86(op) op(ABIX86);

#define LLDB_PROCESS_AMDGPU(op)
#define LLDB_PROCESS_AVR(op)
#define LLDB_PROCESS_BPF(op)
#define LLDB_PROCESS_Lanai(op)
#define LLDB_PROCESS_MSP430(op)
#define LLDB_PROCESS_NVPTX(op)
#define LLDB_PROCESS_RISCV(op)
#define LLDB_PROCESS_Sparc(op)
#define LLDB_PROCESS_WebAssembly(op)
#define LLDB_PROCESS_XCore(op)

llvm::Error SystemInitializerTest::Initialize() {
  if (auto e = SystemInitializerCommon::Initialize())
    return e;

  LLDB_PLUGIN_INITIALIZE(ObjectFileBreakpad);
  LLDB_PLUGIN_INITIALIZE(ObjectFileELF);
  LLDB_PLUGIN_INITIALIZE(ObjectFileMachO);
  LLDB_PLUGIN_INITIALIZE(ObjectFilePECOFF);
  LLDB_PLUGIN_INITIALIZE(ObjectFileWasm);

  LLDB_PLUGIN_INITIALIZE(ObjectContainerBSDArchive);
  LLDB_PLUGIN_INITIALIZE(ObjectContainerMachOArchive);

  LLDB_PLUGIN_INITIALIZE(ScriptInterpreterNone);

  LLDB_PLUGIN_INITIALIZE(PlatformFreeBSD);
  LLDB_PLUGIN_INITIALIZE(PlatformLinux);
  LLDB_PLUGIN_INITIALIZE(PlatformNetBSD);
  LLDB_PLUGIN_INITIALIZE(PlatformOpenBSD);
  LLDB_PLUGIN_INITIALIZE(PlatformWindows);
  LLDB_PLUGIN_INITIALIZE(PlatformAndroid);
  LLDB_PLUGIN_INITIALIZE(PlatformMacOSX);

  // Initialize LLVM and Clang
  llvm::InitializeAllTargets();
  llvm::InitializeAllAsmPrinters();
  llvm::InitializeAllTargetMCs();
  llvm::InitializeAllDisassemblers();

  LLDB_PLUGIN_INITIALIZE(TypeSystemClang);

#define LLVM_TARGET(t) LLDB_PROCESS_##t(LLDB_PLUGIN_INITIALIZE)
#include "llvm/Config/Targets.def"

  LLDB_PLUGIN_INITIALIZE(ArchitectureArm);
  LLDB_PLUGIN_INITIALIZE(ArchitectureMips);
  LLDB_PLUGIN_INITIALIZE(ArchitecturePPC64);

  LLDB_PLUGIN_INITIALIZE(DisassemblerLLVMC);

  LLDB_PLUGIN_INITIALIZE(JITLoaderGDB);
  LLDB_PLUGIN_INITIALIZE(ProcessElfCore);
  LLDB_PLUGIN_INITIALIZE(ProcessMachCore);
  LLDB_PLUGIN_INITIALIZE(ProcessMinidump);
  LLDB_PLUGIN_INITIALIZE(MemoryHistoryASan);
  LLDB_PLUGIN_INITIALIZE(InstrumentationRuntimeASan);
  LLDB_PLUGIN_INITIALIZE(InstrumentationRuntimeTSan);
  LLDB_PLUGIN_INITIALIZE(InstrumentationRuntimeUBSan);
  LLDB_PLUGIN_INITIALIZE(InstrumentationRuntimeMainThreadChecker);

  LLDB_PLUGIN_INITIALIZE(SymbolVendorELF);
  LLDB_PLUGIN_INITIALIZE(SymbolFileBreakpad);
  LLDB_PLUGIN_INITIALIZE(SymbolFileDWARF);
  LLDB_PLUGIN_INITIALIZE(SymbolFilePDB);
  LLDB_PLUGIN_INITIALIZE(SymbolFileSymtab);
  LLDB_PLUGIN_INITIALIZE(SymbolVendorWasm);
  LLDB_PLUGIN_INITIALIZE(UnwindAssemblyInstEmulation);
  LLDB_PLUGIN_INITIALIZE(UnwindAssemblyX86);

  LLDB_PLUGIN_INITIALIZE(InstructionARM);
  LLDB_PLUGIN_INITIALIZE(InstructionARM64);
  LLDB_PLUGIN_INITIALIZE(InstructionMIPS);
  LLDB_PLUGIN_INITIALIZE(InstructionMIPS64);
  LLDB_PLUGIN_INITIALIZE(InstructionPPC64);

  LLDB_PLUGIN_INITIALIZE(CXXItaniumABI);
  LLDB_PLUGIN_INITIALIZE(AppleObjCRuntime);
  LLDB_PLUGIN_INITIALIZE(SystemRuntimeMacOSX);
  LLDB_PLUGIN_INITIALIZE(RenderScriptRuntime);

  LLDB_PLUGIN_INITIALIZE(CPlusPlusLanguage);
  LLDB_PLUGIN_INITIALIZE(ObjCLanguage);
  LLDB_PLUGIN_INITIALIZE(ObjCPlusPlusLanguage);

#if defined(_WIN32)
  LLDB_PLUGIN_INITIALIZE(ProcessWindowsCommon);
#endif
#if defined(__FreeBSD__)
  LLDB_PLUGIN_INITIALIZE(ProcessFreeBSD);
#endif
#if defined(__APPLE__)
  LLDB_PLUGIN_INITIALIZE(SymbolVendorMacOSX);
  LLDB_PLUGIN_INITIALIZE(ProcessMacOSXKernel);
  LLDB_PLUGIN_INITIALIZE(DynamicLoaderDarwinKernel);
#endif

  // This plugin is valid on any host that talks to a Darwin remote. It
  // shouldn't be limited to __APPLE__.
  LLDB_PLUGIN_INITIALIZE(StructuredDataDarwinLog);

  // Platform agnostic plugins
  LLDB_PLUGIN_INITIALIZE(PlatformGDB);

  LLDB_PLUGIN_INITIALIZE(ProcessGDBRemote);
  LLDB_PLUGIN_INITIALIZE(DynamicLoaderMacOSXDYLD);
  LLDB_PLUGIN_INITIALIZE(DynamicLoaderPosixDYLD);
  LLDB_PLUGIN_INITIALIZE(DynamicLoaderWasmDYLD); // Before DynamicLoaderStatic.
  LLDB_PLUGIN_INITIALIZE(DynamicLoaderStatic);
  LLDB_PLUGIN_INITIALIZE(DynamicLoaderWindowsDYLD);

  // Scan for any system or user LLDB plug-ins
  PluginManager::Initialize();

  // The process settings need to know about installed plug-ins, so the
  // Settings must be initialized
  // AFTER PluginManager::Initialize is called.

  Debugger::SettingsInitialize();

  return llvm::Error::success();
}

void SystemInitializerTest::Terminate() {
  static Timer::Category func_cat(LLVM_PRETTY_FUNCTION);
  Timer scoped_timer(func_cat, LLVM_PRETTY_FUNCTION);

  Debugger::SettingsTerminate();

  // Terminate and unload and loaded system or user LLDB plug-ins
  PluginManager::Terminate();

  LLDB_PLUGIN_TERMINATE(TypeSystemClang);

  LLDB_PLUGIN_TERMINATE(ArchitectureArm);
  LLDB_PLUGIN_TERMINATE(ArchitectureMips);
  LLDB_PLUGIN_TERMINATE(ArchitecturePPC64);

#define LLVM_TARGET(t) LLDB_PROCESS_##t(LLDB_PLUGIN_TERMINATE)
#include "llvm/Config/Targets.def"

  LLDB_PLUGIN_TERMINATE(DisassemblerLLVMC);

  LLDB_PLUGIN_TERMINATE(JITLoaderGDB);
  LLDB_PLUGIN_TERMINATE(ProcessElfCore);
  LLDB_PLUGIN_TERMINATE(ProcessMachCore);
  LLDB_PLUGIN_TERMINATE(ProcessMinidump);
  LLDB_PLUGIN_TERMINATE(MemoryHistoryASan);

  LLDB_PLUGIN_TERMINATE(InstrumentationRuntimeASan);
  LLDB_PLUGIN_TERMINATE(InstrumentationRuntimeTSan);
  LLDB_PLUGIN_TERMINATE(InstrumentationRuntimeUBSan);
  LLDB_PLUGIN_TERMINATE(InstrumentationRuntimeMainThreadChecker);

  LLDB_PLUGIN_TERMINATE(SymbolVendorWasm);
  LLDB_PLUGIN_TERMINATE(SymbolVendorELF);
  LLDB_PLUGIN_TERMINATE(SymbolFileBreakpad);
  LLDB_PLUGIN_TERMINATE(SymbolFileDWARF);
  LLDB_PLUGIN_TERMINATE(SymbolFilePDB);
  LLDB_PLUGIN_TERMINATE(SymbolFileSymtab);
  LLDB_PLUGIN_TERMINATE(UnwindAssemblyX86);
  LLDB_PLUGIN_TERMINATE(UnwindAssemblyInstEmulation);

  LLDB_PLUGIN_TERMINATE(InstructionARM);
  LLDB_PLUGIN_TERMINATE(InstructionARM64);
  LLDB_PLUGIN_TERMINATE(InstructionMIPS);
  LLDB_PLUGIN_TERMINATE(InstructionMIPS64);
  LLDB_PLUGIN_TERMINATE(InstructionPPC64);

  LLDB_PLUGIN_TERMINATE(CXXItaniumABI);
  LLDB_PLUGIN_TERMINATE(AppleObjCRuntime);
  LLDB_PLUGIN_TERMINATE(SystemRuntimeMacOSX);
  LLDB_PLUGIN_TERMINATE(RenderScriptRuntime);

  LLDB_PLUGIN_TERMINATE(CPlusPlusLanguage);
  LLDB_PLUGIN_TERMINATE(ObjCLanguage);
  LLDB_PLUGIN_TERMINATE(ObjCPlusPlusLanguage);

#if defined(__APPLE__)
  LLDB_PLUGIN_TERMINATE(DynamicLoaderDarwinKernel);
  LLDB_PLUGIN_TERMINATE(ProcessMacOSXKernel);
  LLDB_PLUGIN_TERMINATE(SymbolVendorMacOSX);
#endif

#if defined(__FreeBSD__)
  LLDB_PLUGIN_TERMINATE(ProcessFreeBSD);
#endif
  Debugger::SettingsTerminate();

  LLDB_PLUGIN_TERMINATE(PlatformGDB);
  LLDB_PLUGIN_TERMINATE(ProcessGDBRemote);
  LLDB_PLUGIN_TERMINATE(StructuredDataDarwinLog);

  LLDB_PLUGIN_TERMINATE(DynamicLoaderMacOSXDYLD);
  LLDB_PLUGIN_TERMINATE(DynamicLoaderPosixDYLD);
  LLDB_PLUGIN_TERMINATE(DynamicLoaderWasmDYLD);
  LLDB_PLUGIN_TERMINATE(DynamicLoaderStatic);
  LLDB_PLUGIN_TERMINATE(DynamicLoaderWindowsDYLD);

  LLDB_PLUGIN_TERMINATE(PlatformFreeBSD);
  LLDB_PLUGIN_TERMINATE(PlatformLinux);
  LLDB_PLUGIN_TERMINATE(PlatformNetBSD);
  LLDB_PLUGIN_TERMINATE(PlatformOpenBSD);
  LLDB_PLUGIN_TERMINATE(PlatformWindows);
  LLDB_PLUGIN_TERMINATE(PlatformAndroid);
  LLDB_PLUGIN_TERMINATE(PlatformMacOSX);

  LLDB_PLUGIN_TERMINATE(ObjectFileBreakpad);
  LLDB_PLUGIN_TERMINATE(ObjectFileELF);
  LLDB_PLUGIN_TERMINATE(ObjectFileMachO);
  LLDB_PLUGIN_TERMINATE(ObjectFilePECOFF);
  LLDB_PLUGIN_TERMINATE(ObjectFileWasm);

  LLDB_PLUGIN_TERMINATE(ObjectContainerBSDArchive);
  LLDB_PLUGIN_TERMINATE(ObjectContainerMachOArchive);

  LLDB_PLUGIN_TERMINATE(ScriptInterpreterNone);

  // Now shutdown the common parts, in reverse order.
  SystemInitializerCommon::Terminate();
}
