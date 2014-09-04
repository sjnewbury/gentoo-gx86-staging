# Copyright 1999-2011 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/eclass/mono.eclass,v 1.15 2011/08/22 04:46:32 vapier Exp $

# @ECLASS: mono.eclass
# @MAINTAINER:
# dotnet@gentoo.org
# @BLURB: common settings and functions for mono and dotnet related packages
# @DESCRIPTION:
# The mono eclass contains common environment settings that are useful for
# dotnet packages.  Currently, it provides no functions, just exports
# MONO_SHARED_DIR and sets LC_ALL in order to prevent errors during compilation
# of dotnet packages.

inherit multilib-minimal

# >=mono-0.92 versions using mcs -pkg:foo-sharp require shared memory, so we set the
# shared dir to ${T} so that ${T}/.wapi can be used during the install process.
export MONO_SHARED_DIR="${T}"

# Building mono, nant and many other dotnet packages is known to fail if LC_ALL
# variable is not set to C. To prevent this all mono related packages will be
# build with LC_ALL=C (see bugs #146424, #149817)
export LC_ALL=C

# Monodevelop-using applications need this to be set or they will try to create config
# files in the user's ~ dir.

export XDG_CONFIG_HOME="${T}"

# Fix bug 83020:
# "Access Violations Arise When Emerging Mono-Related Packages with MONO_AOT_CACHE"

unset MONO_AOT_CACHE

egacinstall() {
	use !prefix && has "${EAPI:-0}" 0 1 2 && ED="${D}"
	gacutil -i "${1}" \
		-root "${ED}"/usr/$(get_libdir) \
		-gacdir /usr/$(get_libdir) \
		-package ${2:-${GACPN:-${PN}}} \
		|| die "installing ${1} into the Global Assembly Cache failed"
}

mono_multilib_comply() {
	use !prefix && has "${EAPI:-0}" 0 1 2 && ED="${D}"
	local dir finddirs=() mv_command=${mv_command:-mv}
	# For each ABI libdir move into a temporary dir so they don't get
	# overridden on every ABI install
	if [[ -d "${ED}/usr/lib" ]]
	then
		if ! [[ -d "${ED}"/usr/lib."${ABI}" ]]
		then
			mkdir "${ED}"/usr/lib."${ABI}" || die "Couldn't mkdir ${ED}/usr/lib.${ABI}"
		fi
		${mv_command} "${ED}"/usr/lib/* "${ED}"/usr/lib."${ABI}"/ || die "Moving files into temporary libdir failed"
		rm -rf "${ED}"/usr/lib
	fi
	if multilib_is_native_abi
	then
		# move everything into the final places
		for this_abi in $(get_all_abis)
		do
			if [[ -d "${ED}"/usr/lib.${this_abi} ]]
			then
				einfo "Fixing up libdir for ${this_abi}"
				if ! [[ -d "${ED}"/usr/"$(get_abi_LIBDIR ${this_abi})" ]]
				then
					mkdir "${ED}"/usr/"$(get_abi_LIBDIR ${this_abi})" || \
						die "Couldn't mkdir ${ED}/usr/$(get_abi_LIBDIR ${this_abi})"
				fi
				${mv_command} "${ED}"/usr/lib.${this_abi}/* "${ED}"/usr/"$(get_abi_LIBDIR ${this_abi})"/ || \
					die "Moving files into correct libdir failed"
				rm -rf "${ED}"/usr/lib."${this_abi}"
					[[ -d "${ED}"/usr/lib."${this_abi}" ]] && \
						${mv_command} "${ED}"/usr/lib."${this_abi}" "${ED}"/usr/"$(get_abi_LIBDIR ${this_abi})"
			fi
			for dir in "${ED}"/usr/"$(get_abi_LIBDIR ${this_abi})"/pkgconfig
			do
				if [[ -d "${dir}" && "$(find "${dir}" -name '*.pc')" != "" ]]
				then
					pushd "${dir}" &> /dev/null
					sed  -i -r -e 's:/(lib)([^a-zA-Z0-9]|$):/'"$(get_abi_LIBDIR ${this_abi})"'\2:g' \
						*.pc \
						|| die "Sedding some sense into pkgconfig files failed."
					popd "${dir}" &> /dev/null
				fi
			done
		done		
		for dir in "${ED}"/usr/share/pkgconfig
		do
				if [[ -d "${dir}" && "$(find "${dir}" -name '*.pc')" != "" ]]
			then
				pushd "${dir}" &> /dev/null
				sed  -i -r -e 's:/(lib)([^a-zA-Z0-9]|$):/'"$(get_libdir)"'\2:g' \
					*.pc \
					|| die "Sedding some sense into pkgconfig files failed."
				popd "${dir}" &> /dev/null
			fi
		done
		if [[ -d "${ED}/usr/bin" ]]
		then
			for exe in "${ED}/usr/bin"/*
			do
				if [[ "$(file "${exe}")" == *"shell script text"* ]]
				then
					sed -r -i -e ":/lib(/|$): s:/lib(/|$):/$(get_libdir)\1:" \
						"${exe}" || die "Sedding some sense into ${exe} failed"
				fi
			done
		fi
	fi
}
