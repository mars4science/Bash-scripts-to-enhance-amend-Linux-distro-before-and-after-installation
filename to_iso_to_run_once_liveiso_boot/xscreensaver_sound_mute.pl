#!/usr/bin/perl

# mutes sound on a system that uses PulseAudio when xsreensaver blanks or locks the screen (if sound is not muted at the time)
my $blanked = 0;
my $toggled = 0;
open (IN, "xscreensaver-command -watch |"); # man perlfaq8: how capture STDOUT of an exernal command 
while (<IN>) {
    if (m/^(BLANK|LOCK)/) { # man xscreensaver-command: LOCK might come either with or without a preceding BLANK 
# (depending on whether the lock-timeout is non-zero), so the program keeps track of both of them
        if (!$blanked) { # A scalar value is interpreted as FALSE in the Boolean sense if ... number 0 (perldata)
            $blanked = 1;
            my $muted = `pactl get-sink-mute \@DEFAULT_SINK\@`; # output "Mute: no" | "Mute: yes" 
            if ( $muted =~ m/no$/ ) {
                system ("pactl set-sink-mute \@DEFAULT_SINK\@ toggle"); # perlfaq8: how run exernal commands 
                $toggled = 1;
            }
        }
    } elsif (m/^UNBLANK/) {
        $blanked = 0;
        if ($toggled) {
            system ("pactl set-sink-mute \@DEFAULT_SINK\@ toggle");
            $toggled = 0;
        }
    }
}
